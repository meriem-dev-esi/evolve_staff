CREATE OR REPLACE FUNCTION public.guard_profile_role_assignments()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF TG_OP = 'INSERT' AND NEW.role IS DISTINCT FROM 'student' THEN
      RAISE EXCEPTION 'New accounts cannot assign their own privileged role'
        USING ERRCODE = '42501';
    END IF;

    IF TG_OP = 'UPDATE' AND NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Profile roles can only be changed by an administrator'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_profile_role_assignments
  ON public.profiles;

CREATE TRIGGER guard_profile_role_assignments
  BEFORE INSERT OR UPDATE OF role
  ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_profile_role_assignments();

CREATE OR REPLACE FUNCTION public.admin_update_profile_role(
  p_actor_id uuid,
  p_target_user_id uuid,
  p_new_role text
)
RETURNS TABLE (
  id uuid,
  email text,
  full_name text,
  role text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_target_role text;
  administrator_count bigint;
BEGIN
  IF p_new_role IS NULL
     OR p_new_role NOT IN ('student', 'teacher', 'admin') THEN
    RAISE EXCEPTION 'Unsupported profile role'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles AS actor
    WHERE actor.id = p_actor_id
      AND actor.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Administrator access required'
      USING ERRCODE = '42501';
  END IF;

  IF p_actor_id = p_target_user_id AND p_new_role <> 'admin' THEN
    RAISE EXCEPTION 'Administrators cannot remove their own admin access'
      USING ERRCODE = '42501';
  END IF;

  LOCK TABLE public.profiles IN SHARE ROW EXCLUSIVE MODE;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles AS actor
    WHERE actor.id = p_actor_id
      AND actor.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Administrator access required'
      USING ERRCODE = '42501';
  END IF;

  SELECT target.role
  INTO current_target_role
  FROM public.profiles AS target
  WHERE target.id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found'
      USING ERRCODE = 'P0002';
  END IF;

  IF current_target_role = 'admin' AND p_new_role <> 'admin' THEN
    SELECT count(*)
    INTO administrator_count
    FROM public.profiles
    WHERE public.profiles.role = 'admin';

    IF administrator_count <= 1 THEN
      RAISE EXCEPTION 'The last administrator cannot be demoted'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN QUERY
  UPDATE public.profiles AS target
  SET role = p_new_role,
      updated_at = now()
  WHERE target.id = p_target_user_id
  RETURNING target.id, target.email, target.full_name, target.role;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_profile_role(uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_profile_role(uuid, uuid, text)
  TO service_role;
