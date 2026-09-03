-- ============================================================
-- FitCircle — Complete Supabase Database Schema
-- Run this in the Supabase SQL editor or use as a migration.
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLE: profiles
-- One row per authenticated user (linked to auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  avatar_url       TEXT,
  daily_step_goal  INTEGER NOT NULL DEFAULT 10000
                   CHECK (daily_step_goal BETWEEN 1000 AND 100000),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'User profile information, one per authenticated user.';

-- ============================================================
-- TABLE: families
-- Represents a "Circle" — a group of family members
-- ============================================================
CREATE TABLE IF NOT EXISTS public.families (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_name  TEXT NOT NULL,
  family_code  TEXT NOT NULL UNIQUE,           -- e.g. FIT-7K92X
  created_by   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT family_code_format CHECK (family_code ~ '^FIT-[A-Z0-9]{5}$')
);

COMMENT ON TABLE public.families IS 'A family circle. Members join using the family_code.';
CREATE INDEX IF NOT EXISTS idx_families_code ON public.families(family_code);

-- ============================================================
-- TABLE: family_members
-- Junction table: which users belong to which family
-- ============================================================
CREATE TABLE IF NOT EXISTS public.family_members (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id  UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (family_id, user_id)   -- A user can only be in a family once
);

COMMENT ON TABLE public.family_members IS 'Members of each family circle.';
CREATE INDEX IF NOT EXISTS idx_fm_family   ON public.family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_fm_user     ON public.family_members(user_id);

-- ============================================================
-- TABLE: daily_steps
-- Step records per user per day
-- UPSERT by (user_id, date) to keep one row per user per day
-- ============================================================
CREATE TABLE IF NOT EXISTS public.daily_steps (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_id   UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  date        DATE NOT NULL DEFAULT CURRENT_DATE,
  steps       INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
  distance    NUMERIC(8,2),    -- in km
  calories    INTEGER,
  source      TEXT NOT NULL DEFAULT 'manual'
              CHECK (source IN ('sensor', 'manual', 'health_connect', 'google_fit')),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, date)       -- One row per user per day
);

COMMENT ON TABLE public.daily_steps IS 'Daily step records. One row per user per day, upserted.';
CREATE INDEX IF NOT EXISTS idx_steps_user_date     ON public.daily_steps(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_steps_family_date   ON public.daily_steps(family_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_steps_date          ON public.daily_steps(date DESC);

-- ============================================================
-- TABLE: exercises
-- Individual workout/exercise records
-- ============================================================
CREATE TABLE IF NOT EXISTS public.exercises (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  family_id         UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  exercise_type     TEXT NOT NULL
                    CHECK (exercise_type IN (
                      'walking','running','cycling','pushups','squats',
                      'plank','jumping_jacks','yoga','stretching',
                      'swimming','gym','other'
                    )),
  duration_minutes  INTEGER CHECK (duration_minutes > 0),
  repetitions       INTEGER CHECK (repetitions > 0),
  sets              INTEGER CHECK (sets > 0),
  distance          NUMERIC(8,2),   -- in km
  notes             TEXT,           -- private — never exposed to other family members
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.exercises IS 'Workout logs. Notes are private and not exposed to other family members.';
CREATE INDEX IF NOT EXISTS idx_exercises_user_date    ON public.exercises(user_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercises_family_date  ON public.exercises(family_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercises_type         ON public.exercises(user_id, exercise_type);

-- ============================================================
-- TABLE: challenges
-- Family challenges with a start/end date and a target
-- ============================================================
CREATE TABLE IF NOT EXISTS public.challenges (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id       UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  target          BIGINT NOT NULL CHECK (target > 0),
  challenge_type  TEXT NOT NULL
                  CHECK (challenge_type IN (
                    'combined_steps','most_steps','most_exercise_minutes',
                    'consecutive_goal_days','monthly_steps'
                  )),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT challenge_dates CHECK (end_date >= start_date)
);

COMMENT ON TABLE public.challenges IS 'Family challenges. Progress is calculated from daily_steps and exercises.';
CREATE INDEX IF NOT EXISTS idx_challenges_family  ON public.challenges(family_id);
CREATE INDEX IF NOT EXISTS idx_challenges_dates   ON public.challenges(start_date, end_date);

-- ============================================================
-- TABLE: achievements
-- Earned achievements per user
-- ============================================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_type TEXT NOT NULL
                   CHECK (achievement_type IN (
                     'first_step','10k_club','25k_day','50k_week',
                     '7_day_warrior','overtaker','comeback',
                     'family_champion','million_steps'
                   )),
  achieved_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, achievement_type)   -- Each achievement earned once
);

COMMENT ON TABLE public.achievements IS 'Achievements unlocked by each user.';
CREATE INDEX IF NOT EXISTS idx_achievements_user ON public.achievements(user_id);

-- ============================================================
-- TABLE: streaks
-- Tracks consecutive daily goal completion
-- ============================================================
CREATE TABLE IF NOT EXISTS public.streaks (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  current_streak  INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  best_streak     INTEGER NOT NULL DEFAULT 0 CHECK (best_streak >= 0),
  last_goal_date  DATE,   -- date of last completed goal, used to detect consecutive days
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.streaks IS 'Current and best goal streaks per user.';
CREATE INDEX IF NOT EXISTS idx_streaks_user ON public.streaks(user_id);

-- ============================================================
-- TABLE: user_settings
-- Per-user app settings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  preferred_units       TEXT NOT NULL DEFAULT 'metric' CHECK (preferred_units IN ('metric','imperial')),
  privacy_settings      JSONB NOT NULL DEFAULT '{"show_exercise_details": false}'::jsonb,
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.user_settings IS 'Per-user app settings.';

-- ============================================================
-- VIEW: family_leaderboard
-- Server-side ranking calculation — clients NEVER submit rank
-- ============================================================
CREATE OR REPLACE VIEW public.family_leaderboard AS
SELECT
  ds.family_id,
  ds.user_id,
  p.name,
  p.avatar_url,
  ds.steps,
  ds.distance,
  ds.calories,
  ds.date,
  RANK() OVER (
    PARTITION BY ds.family_id, ds.date
    ORDER BY ds.steps DESC
  ) AS rank
FROM public.daily_steps ds
JOIN public.profiles p ON p.id = ds.user_id;

COMMENT ON VIEW public.family_leaderboard IS
  'Ranked leaderboard view. Rank is computed server-side from step data — never user-submitted.';

-- ============================================================
-- VIEW: weekly_leaderboard
-- ============================================================
CREATE OR REPLACE VIEW public.weekly_leaderboard AS
SELECT
  ds.family_id,
  ds.user_id,
  p.name,
  p.avatar_url,
  SUM(ds.steps) AS total_steps,
  DATE_TRUNC('week', ds.date) AS week_start,
  RANK() OVER (
    PARTITION BY ds.family_id, DATE_TRUNC('week', ds.date)
    ORDER BY SUM(ds.steps) DESC
  ) AS rank
FROM public.daily_steps ds
JOIN public.profiles p ON p.id = ds.user_id
GROUP BY ds.family_id, ds.user_id, p.name, p.avatar_url, DATE_TRUNC('week', ds.date);

COMMENT ON VIEW public.weekly_leaderboard IS 'Weekly leaderboard aggregated from daily_steps.';

-- ============================================================
-- VIEW: monthly_leaderboard
-- ============================================================
CREATE OR REPLACE VIEW public.monthly_leaderboard AS
SELECT
  ds.family_id,
  ds.user_id,
  p.name,
  p.avatar_url,
  SUM(ds.steps) AS total_steps,
  DATE_TRUNC('month', ds.date) AS month_start,
  RANK() OVER (
    PARTITION BY ds.family_id, DATE_TRUNC('month', ds.date)
    ORDER BY SUM(ds.steps) DESC
  ) AS rank
FROM public.daily_steps ds
JOIN public.profiles p ON p.id = ds.user_id
GROUP BY ds.family_id, ds.user_id, p.name, p.avatar_url, DATE_TRUNC('month', ds.date);

-- ============================================================
-- VIEW: alltime_leaderboard
-- ============================================================
CREATE OR REPLACE VIEW public.alltime_leaderboard AS
SELECT
  ds.family_id,
  ds.user_id,
  p.name,
  p.avatar_url,
  SUM(ds.steps) AS total_steps,
  RANK() OVER (
    PARTITION BY ds.family_id
    ORDER BY SUM(ds.steps) DESC
  ) AS rank
FROM public.daily_steps ds
JOIN public.profiles p ON p.id = ds.user_id
GROUP BY ds.family_id, ds.user_id, p.name, p.avatar_url;

-- ============================================================
-- FUNCTION: generate_family_code()
-- Generates a unique FIT-XXXXX code
-- ============================================================
CREATE OR REPLACE FUNCTION public.generate_family_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  code TEXT;
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no ambiguous chars (0,O,1,I)
  i INTEGER;
BEGIN
  LOOP
    code := 'FIT-';
    FOR i IN 1..5 LOOP
      code := code || SUBSTR(chars, (RANDOM() * LENGTH(chars) + 1)::INTEGER, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.families WHERE family_code = code);
  END LOOP;
  RETURN code;
END;
$$;

COMMENT ON FUNCTION public.generate_family_code IS
  'Generates a unique FIT-XXXXX family code. Retries until a non-duplicate is found.';

-- ============================================================
-- FUNCTION: handle_new_user()
-- Auto-creates profile + streak + settings after signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, name, avatar_url, daily_step_goal)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    10000
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create streak record
  INSERT INTO public.streaks (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  -- Create settings record
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Trigger: run after every new user in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FUNCTION: update_updated_at()
-- Automatically maintains updated_at timestamps
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_daily_steps_updated_at
  BEFORE UPDATE ON public.daily_steps
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_streaks_updated_at
  BEFORE UPDATE ON public.streaks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- FUNCTION: check_and_update_streak()
-- Called after daily_steps upsert to maintain streaks
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_and_update_streak()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  goal       INTEGER;
  last_date  DATE;
  cur_streak INTEGER;
  best       INTEGER;
BEGIN
  -- Get user's daily goal
  SELECT daily_step_goal INTO goal FROM public.profiles WHERE id = NEW.user_id;
  -- Get current streak info
  SELECT current_streak, best_streak, last_goal_date
    INTO cur_streak, best, last_date
    FROM public.streaks WHERE user_id = NEW.user_id;

  -- Only process if goal was just met
  IF NEW.steps >= goal THEN
    IF last_date IS NULL THEN
      -- First ever goal completion
      cur_streak := 1;
    ELSIF last_date = NEW.date - INTERVAL '1 day' THEN
      -- Consecutive day
      cur_streak := cur_streak + 1;
    ELSIF last_date = NEW.date THEN
      -- Same day update, no change
      cur_streak := cur_streak;
    ELSE
      -- Streak broken
      cur_streak := 1;
    END IF;

    best := GREATEST(best, cur_streak);

    UPDATE public.streaks SET
      current_streak = cur_streak,
      best_streak    = best,
      last_goal_date = NEW.date
    WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_streak
  AFTER INSERT OR UPDATE ON public.daily_steps
  FOR EACH ROW EXECUTE FUNCTION public.check_and_update_streak();

-- ============================================================
-- STORAGE: avatars bucket
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', false)
ON CONFLICT (id) DO NOTHING;
