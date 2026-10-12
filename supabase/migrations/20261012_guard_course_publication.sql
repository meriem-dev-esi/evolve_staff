-- Migration: Verrouillage strict de la publication des cours au niveau de la base de données
-- Garantit qu'aucun formateur ou tiers ne peut publier ou dépublier un cours sans le rôle admin

CREATE OR REPLACE FUNCTION public.guard_course_publication()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Vérification pour les requêtes exécutées par un utilisateur authentifié
  IF auth.role() = 'authenticated' THEN
    -- Détection d'une publication à la création ou d'un changement de statut de publication
    IF (TG_OP = 'INSERT' AND NEW.published IS TRUE)
       OR (TG_OP = 'UPDATE' AND NEW.published IS DISTINCT FROM OLD.published) THEN
      
      IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'admin'
      ) THEN
        RAISE EXCEPTION 'Only platform administrators are authorized to publish or unpublish courses'
          USING ERRCODE = '42501';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_course_publication
  ON public.courses;

CREATE TRIGGER guard_course_publication
  BEFORE INSERT OR UPDATE OF published
  ON public.courses
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_course_publication();
