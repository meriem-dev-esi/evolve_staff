-- ============================================================================
-- Evolve Academy: Production Database Performance Indexes & Resilience Schema
-- Migration: 20260920_production_resilience_indexes.sql
-- ============================================================================

-- 1. COURSES PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_courses_published_created 
  ON public.courses (is_published, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_courses_domain_level 
  ON public.courses (domain, level) 
  WHERE is_published = true;

CREATE INDEX IF NOT EXISTS idx_courses_flags 
  ON public.courses (is_beginner, is_partner, is_exclusive, is_trending, is_coming_soon) 
  WHERE is_published = true;

-- 2. ENROLLMENTS & PAYMENT LOOKUPS
CREATE INDEX IF NOT EXISTS idx_enrollments_user_course_paid 
  ON public.enrollments (user_id, course_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_enrollments_user_enrolled 
  ON public.enrollments (user_id, enrolled_at DESC);

-- 3. COMMUNITY PROJECTS & SHOWCASE
CREATE INDEX IF NOT EXISTS idx_community_projects_user_created 
  ON public.community_projects (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_projects_category 
  ON public.community_projects (category);

CREATE INDEX IF NOT EXISTS idx_community_projects_likes 
  ON public.community_projects (likes_count DESC, created_at DESC);

-- 4. COMMUNITY LIKES & COMMENTS
CREATE INDEX IF NOT EXISTS idx_project_likes_project_user 
  ON public.community_project_likes (project_id, user_id);

CREATE INDEX IF NOT EXISTS idx_project_comments_project 
  ON public.community_project_comments (project_id, created_at DESC);

-- 5. LESSON PROGRESS & WATCHLIST
CREATE INDEX IF NOT EXISTS idx_lesson_progress_user_lesson 
  ON public.lesson_progress (user_id, lesson_id);

CREATE INDEX IF NOT EXISTS idx_lesson_progress_user_completed 
  ON public.lesson_progress (user_id, completed);

CREATE INDEX IF NOT EXISTS idx_lessons_course_order 
  ON public.lessons (course_id, order_index ASC);

-- 6. DIRECT MESSAGING & CHAT SCHEMA
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Active le RLS sur les conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.direct_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE, -- Type corrigé + FK
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_direct_messages_conversation 
  ON public.direct_messages (conversation_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_direct_messages_receiver_read 
  ON public.direct_messages (receiver_id, is_read);

-- Row Level Security pour Direct Messages
ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read messages they sent or received"
  ON public.direct_messages
  FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages where they are the sender"
  ON public.direct_messages
  FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- RLS pour Conversations : Seuls les participants aux messages de la conversation peuvent la lire
CREATE POLICY "Users can read conversations they belong to"
  ON public.conversations
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.direct_messages
      WHERE conversation_id = public.conversations.id
      AND (sender_id = auth.uid() OR receiver_id = auth.uid())
    )
  );