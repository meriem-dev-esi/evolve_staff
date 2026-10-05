-- Migration: Allow authenticated staff to manage (insert, update, delete) course_series and series_courses

-- 1. Enable RLS on both tables
ALTER TABLE public.course_series ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_courses ENABLE ROW LEVEL SECURITY;

-- 2. RLS Policies for course_series
DROP POLICY IF EXISTS "Public read course_series" ON public.course_series;
DROP POLICY IF EXISTS "Anyone can select course_series" ON public.course_series;
CREATE POLICY "Anyone can select course_series"
  ON public.course_series
  FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Authenticated can insert course_series" ON public.course_series;
DROP POLICY IF EXISTS "Staff can insert course_series" ON public.course_series;
CREATE POLICY "Staff can insert course_series"
  ON public.course_series
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can update course_series" ON public.course_series;
DROP POLICY IF EXISTS "Staff can update course_series" ON public.course_series;
CREATE POLICY "Staff can update course_series"
  ON public.course_series
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can delete course_series" ON public.course_series;
DROP POLICY IF EXISTS "Staff can delete course_series" ON public.course_series;
CREATE POLICY "Staff can delete course_series"
  ON public.course_series
  FOR DELETE
  TO authenticated
  USING (true);

-- 3. RLS Policies for series_courses
DROP POLICY IF EXISTS "Public read series_courses" ON public.series_courses;
DROP POLICY IF EXISTS "Anyone can select series_courses" ON public.series_courses;
CREATE POLICY "Anyone can select series_courses"
  ON public.series_courses
  FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Authenticated can insert series_courses" ON public.series_courses;
DROP POLICY IF EXISTS "Staff can insert series_courses" ON public.series_courses;
CREATE POLICY "Staff can insert series_courses"
  ON public.series_courses
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can update series_courses" ON public.series_courses;
DROP POLICY IF EXISTS "Staff can update series_courses" ON public.series_courses;
CREATE POLICY "Staff can update series_courses"
  ON public.series_courses
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can delete series_courses" ON public.series_courses;
DROP POLICY IF EXISTS "Staff can delete series_courses" ON public.series_courses;
CREATE POLICY "Staff can delete series_courses"
  ON public.series_courses
  FOR DELETE
  TO authenticated
  USING (true);
