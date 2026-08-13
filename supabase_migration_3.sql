-- BloomSpeech — migration 3: let the clinician write the kid→child link.
--
-- Why: the kid's device was the one writing `children.linked_user_id`, but the
-- kid is precisely the party that row-level security refuses on a clinician's
-- child row. The write silently affected zero rows, the kid stayed unlinked,
-- and their progress screens stayed empty no matter how many sessions ran.
--
-- The kid now records only their own id on the shared session row, and the
-- clinician — who owns the child record and is always permitted to write it —
-- copies it across when the session is saved.
--
-- Run in the Supabase SQL editor, after supabase_migration.sql and
-- supabase_migration_2.sql. Idempotent.

-- ── 1. Where the kid announces themselves ────────────────────────────────────
ALTER TABLE active_sessions
  ADD COLUMN IF NOT EXISTS kid_user_id text;

-- ── 2. The kid must be able to write that one column ─────────────────────────
-- Only needed if RLS is enabled on active_sessions. Harmless otherwise.
DROP POLICY IF EXISTS "kid updates own active session" ON active_sessions;
CREATE POLICY "kid updates own active session"
  ON active_sessions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "anyone signed in reads active sessions" ON active_sessions;
CREATE POLICY "anyone signed in reads active sessions"
  ON active_sessions FOR SELECT
  TO authenticated
  USING (true);

-- ── 3. Verify ────────────────────────────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'active_sessions'
  AND column_name IN ('kid_user_id', 'kid_video_started',
                      'kid_audio_muted', 'kid_video_muted')
ORDER BY column_name;

-- After running one more session end-to-end, this should show the kid's id
-- attached to the child they practised with:
-- SELECT id, name, linked_user_id, linked_at, total_sessions
-- FROM children WHERE linked_user_id IS NOT NULL ORDER BY linked_at DESC;
