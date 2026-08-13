-- BloomSpeech — migration 2: make the kid→child link single-valued and ordered.
--
-- Problem this fixes: `linked_user_id` was treated as a pointer but never
-- cleared, so a kid who joined sessions for more than one child ended up
-- stamped on several rows. The lookup then did `limit(1)` with no ORDER BY,
-- and Postgres is free to return any of them — in practice the same stale one
-- every time. The kid saw an old child's session count and it never moved,
-- however many new sessions were run.
--
-- Run in the Supabase SQL editor. Idempotent.

-- ── 1. When the link was last set, so the lookup can order deterministically ──
ALTER TABLE children
  ADD COLUMN IF NOT EXISTS linked_at timestamptz;

-- Backfill existing links so they sort predictably instead of as NULL.
UPDATE children
SET linked_at = COALESCE(linked_at, now())
WHERE linked_user_id IS NOT NULL
  AND linked_at IS NULL;

-- ── 2. Enforce one child per kid at the database level ───────────────────────
-- Belt and braces: the app now clears other links before setting a new one,
-- but this makes a duplicate impossible even if a write path is missed.
-- If this fails, you have pre-existing duplicates — clean them with step 3
-- first, then re-run.
CREATE UNIQUE INDEX IF NOT EXISTS children_linked_user_id_unique
  ON children (linked_user_id)
  WHERE linked_user_id IS NOT NULL;

-- ── 3. Inspect / repair existing duplicate links ─────────────────────────────
-- Any kid listed here is stamped on more than one child and is what caused the
-- wrong session count. Review before running the repair below.
SELECT linked_user_id,
       count(*)                        AS linked_children,
       array_agg(name ORDER BY name)   AS child_names,
       array_agg(total_sessions)       AS session_counts
FROM children
WHERE linked_user_id IS NOT NULL
GROUP BY linked_user_id
HAVING count(*) > 1;

-- Repair: keep only the most recently linked child for each kid.
-- Uncomment and run if the query above returned any rows.
-- UPDATE children c
-- SET linked_user_id = NULL, linked_at = NULL
-- WHERE c.linked_user_id IS NOT NULL
--   AND c.id <> (
--     SELECT c2.id FROM children c2
--     WHERE c2.linked_user_id = c.linked_user_id
--     ORDER BY c2.linked_at DESC NULLS LAST, c2.total_sessions DESC
--     LIMIT 1
--   );

-- ── 4. Verify: one row per kid, pointing at the intended child ───────────────
SELECT linked_user_id, id AS child_id, name, total_sessions, linked_at
FROM children
WHERE linked_user_id IS NOT NULL
ORDER BY linked_at DESC;
