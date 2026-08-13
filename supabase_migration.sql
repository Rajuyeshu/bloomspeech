-- BloomSpeech — schema additions required by the clinician-control and
-- kid-progress fixes. Run this in the Supabase SQL editor.
--
-- All statements are idempotent, so re-running is safe.

-- ── 1. Link a kid's login to the clinician's child record ────────────────────
-- Sessions are saved against the clinician's child row. Without this column a
-- kid's home and progress screens query their own separate profile and always
-- show zero. Stamped automatically the first time a kid joins with a code.
ALTER TABLE children
  ADD COLUMN IF NOT EXISTS linked_user_id text;

CREATE INDEX IF NOT EXISTS children_linked_user_id_idx
  ON children (linked_user_id);

-- ── 2. Clinician control over the kid's video call ───────────────────────────
-- The kid's device polls these and applies them to its own Jitsi client.
-- kid_video_started stays false until the clinician starts the call, so the
-- kid never joins on their own.
ALTER TABLE active_sessions
  ADD COLUMN IF NOT EXISTS kid_video_started boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS kid_audio_muted   boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS kid_video_muted   boolean NOT NULL DEFAULT false;

-- ── 3. Verify ────────────────────────────────────────────────────────────────
-- Expect: linked_user_id on children; three kid_* columns on active_sessions.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE (table_name = 'children'        AND column_name = 'linked_user_id')
   OR (table_name = 'active_sessions' AND column_name LIKE 'kid_%')
ORDER BY table_name, column_name;
