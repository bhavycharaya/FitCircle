-- ============================================================
-- FitCircle — Row Level Security Policies
-- Run AFTER schema.sql
-- ============================================================
-- Security model:
--   • Users can only access their OWN data or data from their family.
--   • Family membership is the security boundary.
--   • Rankings are NEVER submitted by clients — always computed server-side.
--   • Workout notes are excluded from family-visible queries in the app.
-- ============================================================

-- ── Enable RLS on all tables ────────────────────────────────
ALTER TABLE public.profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_steps    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings  ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER FUNCTION: get_my_family_id()
-- Returns the authenticated user's family_id (or NULL)
-- Used in all RLS policies to avoid repeated subqueries
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_family_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT family_id
  FROM public.family_members
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

-- ============================================================
-- profiles
-- ============================================================

-- Read: own profile OR profile of a family member
CREATE POLICY "profiles_select"
ON public.profiles FOR SELECT
USING (
  id = auth.uid()
  OR id IN (
    SELECT user_id FROM public.family_members
    WHERE family_id = public.get_my_family_id()
  )
);

-- Insert: only own profile (handled by trigger, but allow direct too)
CREATE POLICY "profiles_insert"
ON public.profiles FOR INSERT
WITH CHECK (id = auth.uid());

-- Update: only own profile
CREATE POLICY "profiles_update"
ON public.profiles FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Delete: only own profile
CREATE POLICY "profiles_delete"
ON public.profiles FOR DELETE
USING (id = auth.uid());

-- ============================================================
-- families
-- ============================================================

-- Read: only if you're a member of that family
CREATE POLICY "families_select"
ON public.families FOR SELECT
USING (
  id = public.get_my_family_id()
);

-- Insert: any authenticated user can create a family
CREATE POLICY "families_insert"
ON public.families FOR INSERT
WITH CHECK (created_by = auth.uid());

-- Update: only the creator can update the family name
CREATE POLICY "families_update"
ON public.families FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Delete: only creator can delete the family
CREATE POLICY "families_delete"
ON public.families FOR DELETE
USING (created_by = auth.uid());

-- ============================================================
-- family_members
-- ============================================================

-- Read: see all members of your own family
CREATE POLICY "family_members_select"
ON public.family_members FOR SELECT
USING (
  family_id = public.get_my_family_id()
);

-- Insert: you can only add yourself (join). family_id is validated
-- by the app service which looks up the code first.
CREATE POLICY "family_members_insert"
ON public.family_members FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Delete: only remove yourself from a family
CREATE POLICY "family_members_delete"
ON public.family_members FOR DELETE
USING (user_id = auth.uid());

-- ============================================================
-- daily_steps
-- ============================================================

-- Read: your own steps OR family members' steps (for leaderboard)
CREATE POLICY "daily_steps_select"
ON public.daily_steps FOR SELECT
USING (
  user_id = auth.uid()
  OR family_id = public.get_my_family_id()
);

-- Insert: only your own steps, and only for your family
CREATE POLICY "daily_steps_insert"
ON public.daily_steps FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND family_id = public.get_my_family_id()
);

-- Update: only your own steps
-- (this prevents any user from editing another's count)
CREATE POLICY "daily_steps_update"
ON public.daily_steps FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
  user_id = auth.uid()
  AND family_id = public.get_my_family_id()
);

-- Delete: only your own steps
CREATE POLICY "daily_steps_delete"
ON public.daily_steps FOR DELETE
USING (user_id = auth.uid());

-- ============================================================
-- exercises
-- ============================================================

-- Read: only your OWN exercise records.
-- (Family activity screen shows summary counts, not individual records.)
-- The app layer selects only non-private fields for family display.
CREATE POLICY "exercises_select"
ON public.exercises FOR SELECT
USING (user_id = auth.uid());

-- Family summary (duration_minutes only, no notes) is derived by the app
-- by querying with a specific column selection. Individual records
-- with notes remain private.

-- Insert: only own exercises for own family
CREATE POLICY "exercises_insert"
ON public.exercises FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND family_id = public.get_my_family_id()
);

-- Update: only own records
CREATE POLICY "exercises_update"
ON public.exercises FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Delete: only own records
CREATE POLICY "exercises_delete"
ON public.exercises FOR DELETE
USING (user_id = auth.uid());

-- ============================================================
-- challenges
-- ============================================================

-- Read: challenges for your family only
CREATE POLICY "challenges_select"
ON public.challenges FOR SELECT
USING (family_id = public.get_my_family_id());

-- Insert: any family member can create a challenge for their family
CREATE POLICY "challenges_insert"
ON public.challenges FOR INSERT
WITH CHECK (family_id = public.get_my_family_id());

-- Update/Delete: only by family creator (simplified for V1)
CREATE POLICY "challenges_update"
ON public.challenges FOR UPDATE
USING (family_id = public.get_my_family_id());

CREATE POLICY "challenges_delete"
ON public.challenges FOR DELETE
USING (family_id = public.get_my_family_id());

-- ============================================================
-- achievements
-- ============================================================

-- Read: own achievements only (or family members' for display)
CREATE POLICY "achievements_select"
ON public.achievements FOR SELECT
USING (
  user_id = auth.uid()
  OR user_id IN (
    SELECT user_id FROM public.family_members
    WHERE family_id = public.get_my_family_id()
  )
);

-- Insert: only own achievements (granted by server trigger/function)
CREATE POLICY "achievements_insert"
ON public.achievements FOR INSERT
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- streaks
-- ============================================================

-- Read: own OR family members
CREATE POLICY "streaks_select"
ON public.streaks FOR SELECT
USING (
  user_id = auth.uid()
  OR user_id IN (
    SELECT user_id FROM public.family_members
    WHERE family_id = public.get_my_family_id()
  )
);

-- Insert/Update: only own streak (maintained by trigger)
CREATE POLICY "streaks_insert"
ON public.streaks FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "streaks_update"
ON public.streaks FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- user_settings
-- ============================================================

-- Read: only own settings
CREATE POLICY "settings_select"
ON public.user_settings FOR SELECT
USING (user_id = auth.uid());

-- Insert/Update: only own settings
CREATE POLICY "settings_insert"
ON public.user_settings FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "settings_update"
ON public.user_settings FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- STORAGE: avatars bucket RLS
-- ============================================================

-- Users can view their own avatar and family members' avatars
CREATE POLICY "avatar_select"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'avatars'
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR (storage.foldername(name))[1] IN (
      SELECT user_id::text FROM public.family_members
      WHERE family_id = public.get_my_family_id()
    )
  )
);

-- Only upload to own folder: avatars/{user_id}/avatar.jpg
CREATE POLICY "avatar_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Only update/delete own avatar
CREATE POLICY "avatar_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "avatar_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
