-- Solution définitive pour autoriser l'ajout, la modification et la suppression de formations et de cours associés
-- À exécuter dans le Supabase SQL Editor : https://supabase.com/dashboard/project/ficrjocgrcghxrdpwbbw/sql

-- 1. Désactiver les restrictions RLS sur les tables de formations
ALTER TABLE public.series_courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_series DISABLE ROW LEVEL SECURITY;

-- 2. Accorder tous les droits de lecture / écriture / suppression
GRANT ALL ON TABLE public.series_courses TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.course_series TO anon, authenticated, service_role;

-- 3. Si des séquences ou IDs sont utilisés
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
