-- Restrict direct messaging to student <-> teacher conversations.
-- This migration can be reapplied safely if a previous SQL Editor run stopped
-- after creating some of the policies.

CREATE OR REPLACE FUNCTION public.messaging_role_group(p_role TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
AS $role$
  SELECT CASE LOWER(BTRIM(COALESCE(p_role, '')))
    WHEN 'student' THEN 'student'
    WHEN 'étudiant' THEN 'student'
    WHEN 'étudiante' THEN 'student'
    WHEN 'étudiant evolve' THEN 'student'
    WHEN 'étudiante evolve' THEN 'student'
    WHEN 'teacher' THEN 'teacher'
    WHEN 'formateur' THEN 'teacher'
    WHEN 'formatrice' THEN 'teacher'
    WHEN 'enseignant' THEN 'teacher'
    WHEN 'enseignante' THEN 'teacher'
    WHEN 'instructor' THEN 'teacher'
    ELSE NULL
  END;
$role$;

GRANT EXECUTE ON FUNCTION public.messaging_role_group(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.messaging_roles_allow_pair(
  p_first_user UUID,
  p_second_user UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $pair$
  SELECT
    public.messaging_role_group(first_profile.role)
      <> public.messaging_role_group(second_profile.role)
    AND public.messaging_role_group(first_profile.role) IS NOT NULL
    AND public.messaging_role_group(second_profile.role) IS NOT NULL
  FROM public.profiles AS first_profile
  JOIN public.profiles AS second_profile
    ON second_profile.id = p_second_user
  WHERE first_profile.id = p_first_user;
$pair$;

REVOKE ALL ON FUNCTION public.messaging_roles_allow_pair(UUID, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.messaging_roles_allow_pair(UUID, UUID)
  TO authenticated;

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
  v_user_role TEXT;
  v_recipient_role TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_user_id = p_recipient_id THEN
    RAISE EXCEPTION 'Cannot create conversation with yourself';
  END IF;

  SELECT public.messaging_role_group(role)
  INTO v_user_role
  FROM public.profiles
  WHERE id = v_user_id;

  SELECT public.messaging_role_group(role)
  INTO v_recipient_role
  FROM public.profiles
  WHERE id = p_recipient_id;

  IF v_user_role IS NULL
     OR v_recipient_role IS NULL
     OR v_user_role = v_recipient_role THEN
    RAISE EXCEPTION 'Messaging is only allowed between students and teachers';
  END IF;

  v_p1 := LEAST(v_user_id, p_recipient_id);
  v_p2 := GREATEST(v_user_id, p_recipient_id);

  SELECT id INTO v_conv_id
  FROM public.conversations
  WHERE (participant_one = v_p1 AND participant_two = v_p2)
     OR (participant_one = v_p2 AND participant_two = v_p1)
  LIMIT 1;

  IF v_conv_id IS NULL THEN
    SELECT conversation_id INTO v_conv_id
    FROM public.direct_messages
    WHERE (sender_id = v_user_id AND receiver_id = p_recipient_id)
       OR (sender_id = p_recipient_id AND receiver_id = v_user_id)
    LIMIT 1;
  END IF;

  IF v_conv_id IS NOT NULL THEN
    UPDATE public.conversations
    SET participant_one = v_p1, participant_two = v_p2
    WHERE id = v_conv_id
      AND (participant_one IS NULL OR participant_two IS NULL);
  ELSE
    INSERT INTO public.conversations (participant_one, participant_two, updated_at)
    VALUES (v_p1, v_p2, now())
    RETURNING id INTO v_conv_id;
  END IF;

  RETURN v_conv_id;
END;
$func$;

REVOKE ALL ON FUNCTION public.get_or_create_conversation(UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID)
  TO authenticated;

WITH conversation_users AS (
  SELECT conversation_id, sender_id AS user_id
  FROM public.direct_messages
  UNION
  SELECT conversation_id, receiver_id AS user_id
  FROM public.direct_messages
),
participant_pairs AS (
  SELECT
    conversation_id,
    (ARRAY_AGG(user_id ORDER BY user_id))[1] AS participant_one,
    (ARRAY_AGG(user_id ORDER BY user_id))[2] AS participant_two
  FROM conversation_users
  GROUP BY conversation_id
  HAVING COUNT(*) = 2
)
UPDATE public.conversations AS conversation
SET
  participant_one = participant_pairs.participant_one,
  participant_two = participant_pairs.participant_two
FROM participant_pairs
WHERE conversation.id = participant_pairs.conversation_id
  AND (
    conversation.participant_one IS NULL
    OR conversation.participant_two IS NULL
  );

DROP POLICY IF EXISTS "Users can read conversations they belong to"
  ON public.conversations;
DROP POLICY IF EXISTS "Users can insert conversations they belong to"
  ON public.conversations;
DROP POLICY IF EXISTS "Users can read student teacher conversations"
  ON public.conversations;
CREATE POLICY "Users can read student teacher conversations"
  ON public.conversations
  FOR SELECT
  USING (
    (
      auth.uid() = participant_one
      AND public.messaging_roles_allow_pair(participant_one, participant_two)
    )
    OR (
      auth.uid() = participant_two
      AND public.messaging_roles_allow_pair(participant_two, participant_one)
    )
  );

DROP POLICY IF EXISTS "Users can create student teacher conversations"
  ON public.conversations;
CREATE POLICY "Users can create student teacher conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK (
    (auth.uid() = participant_one OR auth.uid() = participant_two)
    AND
    public.messaging_roles_allow_pair(participant_one, participant_two)
  );

DROP POLICY IF EXISTS "Users can send messages"
  ON public.direct_messages;
DROP POLICY IF EXISTS "Users can insert messages where they are the sender"
  ON public.direct_messages;
DROP POLICY IF EXISTS "Users can message between students and teachers"
  ON public.direct_messages;
CREATE POLICY "Users can message between students and teachers"
  ON public.direct_messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1
      FROM public.conversations AS conversation
      WHERE conversation.id = conversation_id
        AND (
          (
            conversation.participant_one = sender_id
            AND conversation.participant_two = receiver_id
          )
          OR (
            conversation.participant_two = sender_id
            AND conversation.participant_one = receiver_id
          )
        )
        AND public.messaging_roles_allow_pair(sender_id, receiver_id)
    )
  );

DROP POLICY IF EXISTS "Users can read messages they sent or received"
  ON public.direct_messages;
DROP POLICY IF EXISTS "Users can read student teacher messages"
  ON public.direct_messages;
CREATE POLICY "Users can read student teacher messages"
  ON public.direct_messages
  FOR SELECT
  USING (
    (auth.uid() = sender_id OR auth.uid() = receiver_id)
    AND public.messaging_roles_allow_pair(sender_id, receiver_id)
  );

DROP POLICY IF EXISTS "Receivers can mark messages as read"
  ON public.direct_messages;
DROP POLICY IF EXISTS "Receivers can mark student teacher messages as read"
  ON public.direct_messages;
CREATE POLICY "Receivers can mark student teacher messages as read"
  ON public.direct_messages
  FOR UPDATE
  USING (
    auth.uid() = receiver_id
    AND public.messaging_roles_allow_pair(sender_id, receiver_id)
  )
  WITH CHECK (
    auth.uid() = receiver_id
    AND public.messaging_roles_allow_pair(sender_id, receiver_id)
  );
