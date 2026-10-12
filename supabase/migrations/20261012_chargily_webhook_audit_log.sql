-- Migration: Création de la table de journalisation et d'audit des webhooks Chargily Pay
-- Permet la traçabilité intégrale, l'idempotence et la résolution de litiges monétaires

CREATE TABLE IF NOT EXISTS public.chargily_webhook_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text,
  checkout_id text,
  amount_received integer,
  currency text DEFAULT 'dzd',
  status text NOT NULL,
  signature_verified boolean NOT NULL DEFAULT false,
  raw_payload jsonb NOT NULL,
  processing_error text,
  processed_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Index pour réconciliation rapide par checkout_id
CREATE INDEX IF NOT EXISTS idx_chargily_webhook_events_checkout_id
  ON public.chargily_webhook_events (checkout_id);

CREATE INDEX IF NOT EXISTS idx_chargily_webhook_events_created_at
  ON public.chargily_webhook_events (created_at DESC);

-- Activation de RLS : table strictement privée réservée au service_role et administrateurs
ALTER TABLE public.chargily_webhook_events ENABLE ROW LEVEL SECURITY;

GRANT ALL ON public.chargily_webhook_events TO service_role;

DROP POLICY IF EXISTS "Admins can view webhook audit logs" ON public.chargily_webhook_events;

CREATE POLICY "Admins can view webhook audit logs"
  ON public.chargily_webhook_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
