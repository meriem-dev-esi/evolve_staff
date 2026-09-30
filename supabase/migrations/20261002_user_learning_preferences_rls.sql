ALTER TABLE public.user_learning_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own learning preferences"
  ON public.user_learning_preferences;
CREATE POLICY "Users can read their own learning preferences"
  ON public.user_learning_preferences
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create their own learning preferences"
  ON public.user_learning_preferences;
CREATE POLICY "Users can create their own learning preferences"
  ON public.user_learning_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own learning preferences"
  ON public.user_learning_preferences;
CREATE POLICY "Users can update their own learning preferences"
  ON public.user_learning_preferences
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
