-- ============================================================================
-- Evolve Academy: Community Likes RPC & Real-time Direct Messaging Hardening
-- Migration: 20260930_community_likes_and_messaging.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. COMMUNITY PROJECT LIKES & RPC
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.community_project_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.community_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (project_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_project_likes_project_user 
  ON public.community_project_likes (project_id, user_id);

ALTER TABLE public.community_project_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access to project likes" ON public.community_project_likes;
CREATE POLICY "Public read access to project likes"
  ON public.community_project_likes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can manage own likes" ON public.community_project_likes;
CREATE POLICY "Users can manage own likes"
  ON public.community_project_likes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.toggle_project_like(p_project_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
  v_user_id UUID := auth.uid();
  v_liked BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.community_project_likes
    WHERE project_id = p_project_id AND user_id = v_user_id
  ) THEN
    DELETE FROM public.community_project_likes
    WHERE project_id = p_project_id AND user_id = v_user_id;

    UPDATE public.community_projects
    SET likes_count = GREATEST(0, COALESCE(likes_count, 1) - 1)
    WHERE id = p_project_id;

    v_liked := false;
  ELSE
    INSERT INTO public.community_project_likes (project_id, user_id)
    VALUES (p_project_id, v_user_id)
    ON CONFLICT (project_id, user_id) DO NOTHING;

    UPDATE public.community_projects
    SET likes_count = COALESCE(likes_count, 0) + 1
    WHERE id = p_project_id;

    v_liked := true;
  END IF;

  RETURN v_liked;
END;
$func$;

GRANT EXECUTE ON FUNCTION public.toggle_project_like(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 2. ENHANCED CONVERSATIONS SCHEMA & PAIR TRACKING
-- ----------------------------------------------------------------------------
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS participant_one UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS participant_two UUID REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_conversations_participants 
  ON public.conversations (participant_one, participant_two);

DROP POLICY IF EXISTS "Users can read conversations they belong to" ON public.conversations;
CREATE POLICY "Users can read conversations they belong to"
  ON public.conversations
  FOR SELECT
  USING (
    auth.uid() = participant_one OR 
    auth.uid() = participant_two OR
    EXISTS (
      SELECT 1 FROM public.direct_messages
      WHERE conversation_id = public.conversations.id
      AND (sender_id = auth.uid() OR receiver_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert conversations they belong to" ON public.conversations;
CREATE POLICY "Users can insert conversations they belong to"
  ON public.conversations
  FOR INSERT
  WITH CHECK (
    auth.uid() = participant_one OR auth.uid() = participant_two
  );

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(p_recipient_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
  v_user_id UUID := auth.uid();
  v_conv_id UUID;
  v_p1 UUID;
  v_p2 UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_user_id = p_recipient_id THEN
    RAISE EXCEPTION 'Cannot create conversation with yourself';
  END IF;

  v_p1 := LEAST(v_user_id, p_recipient_id);
  v_p2 := GREATEST(v_user_id, p_recipient_id);

  -- 1. Try to find existing conversation by participants
  SELECT id INTO v_conv_id
  FROM public.conversations
  WHERE (participant_one = v_p1 AND participant_two = v_p2)
     OR (participant_one = v_p2 AND participant_two = v_p1)
  LIMIT 1;

  -- 2. Try to find existing conversation from messages history
  IF v_conv_id IS NULL THEN
    SELECT conversation_id INTO v_conv_id
    FROM public.direct_messages
    WHERE (sender_id = v_user_id AND receiver_id = p_recipient_id)
       OR (sender_id = p_recipient_id AND receiver_id = v_user_id)
    LIMIT 1;
  END IF;

  -- 3. If found, ensure participants columns are populated
  IF v_conv_id IS NOT NULL THEN
    UPDATE public.conversations
    SET participant_one = v_p1, participant_two = v_p2
    WHERE id = v_conv_id AND (participant_one IS NULL OR participant_two IS NULL);
  ELSE
    -- 4. Otherwise create a brand new conversation
    INSERT INTO public.conversations (participant_one, participant_two, updated_at)
    VALUES (v_p1, v_p2, now())
    RETURNING id INTO v_conv_id;
  END IF;

  RETURN v_conv_id;
END;
$func$;

GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 3. DIRECT MESSAGES RLS FOR READ RECEIPTS & REPLICATION
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Receivers can mark messages as read" ON public.direct_messages;
CREATE POLICY "Receivers can mark messages as read"
  ON public.direct_messages
  FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Enable publication in Supabase Realtime
DO $realtime$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'direct_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'community_project_comments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_project_comments;
  END IF;
END;
$realtime$;
