-- ============================================================================
-- Evolve Academy: Production Orders, Webhook Idempotency & RLS Hardening
-- Migration: 20260924_orders_and_rls_hardening.sql
-- ============================================================================

-- 1. ORDERS TABLE (Financial transaction records)
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE RESTRICT,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  currency VARCHAR(10) NOT NULL DEFAULT 'dzd',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'canceled')),
  payment_method VARCHAR(50) DEFAULT 'edahabia',
  chargily_checkout_id TEXT UNIQUE,
  chargily_payment_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance & quick webhook lookup
CREATE INDEX IF NOT EXISTS idx_orders_user_created ON public.orders (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_chargily_checkout ON public.orders (chargily_checkout_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_course ON public.orders (course_id);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Drop prior policies if any
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert their pending orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;

-- Users can only view their own orders
CREATE POLICY "Users can view their own orders"
  ON public.orders
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create pending orders for themselves
CREATE POLICY "Users can insert their pending orders"
  ON public.orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Only service role can update order statuses (e.g. marking paid via webhook)


-- 2. WEBHOOK EVENTS TABLE (Idempotency and Audit Log)
CREATE TABLE IF NOT EXISTS public.webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id TEXT NOT NULL UNIQUE,
  event_type VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_id ON public.webhook_events (event_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON public.webhook_events (processed_at DESC);

-- Enable RLS (Service role only, no public access)
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;


-- 3. ENROLLMENTS TABLE RLS HARDENING
ALTER TABLE IF EXISTS public.enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Users can read own enrollments" ON public.enrollments;

CREATE POLICY "Users can view their own enrollments"
  ON public.enrollments
  FOR SELECT
  USING (auth.uid() = user_id);


-- 4. FIX INSECURE DIRECT MESSAGES POLICIES IF PRESENT
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'direct_messages' AND policyname = 'Users can read their messages'
  ) THEN
    DROP POLICY "Users can read their messages" ON public.direct_messages;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'direct_messages' AND policyname = 'Users can send messages'
  ) THEN
    DROP POLICY "Users can send messages" ON public.direct_messages;
  END IF;
END $$;

-- Enforce strict sender/receiver isolation
DROP POLICY IF EXISTS "Users can read messages they sent or received" ON public.direct_messages;
CREATE POLICY "Users can read messages they sent or received"
  ON public.direct_messages
  FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert messages where they are the sender" ON public.direct_messages;
CREATE POLICY "Users can insert messages where they are the sender"
  ON public.direct_messages
  FOR INSERT
  WITH CHECK (auth.uid() = sender_id);
