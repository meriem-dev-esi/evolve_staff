CREATE OR REPLACE FUNCTION public.get_messaging_contact_profiles(
  p_user_ids UUID[]
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  role TEXT
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT profile.id, profile.full_name, profile.role
  FROM public.profiles AS profile
  WHERE auth.uid() IS NOT NULL
    AND profile.id = ANY(COALESCE(p_user_ids, ARRAY[]::UUID[]))
    AND public.messaging_roles_allow_pair(auth.uid(), profile.id)
    AND EXISTS (
      SELECT 1
      FROM public.conversations AS conversation
      WHERE (
        conversation.participant_one = auth.uid()
        AND conversation.participant_two = profile.id
      ) OR (
        conversation.participant_two = auth.uid()
        AND conversation.participant_one = profile.id
      )
    );
$function$;

REVOKE ALL ON FUNCTION public.get_messaging_contact_profiles(UUID[])
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_messaging_contact_profiles(UUID[])
  TO authenticated;
