-- BloomSpeech — let a linked kid read their own therapy data.
--
-- Sessions are stored against the CLINICIAN's child row. If row-level security
-- on `children` / `sessions` only admits the owning clinician, a kid's login is
-- refused and their progress screens come back empty even though the rows
-- plainly exist in the table. That is the "it's in the database but the kid
-- can't see it" symptom.
--
-- Run this in the Supabase SQL editor AFTER supabase_migration.sql.

-- ── Step 0: is RLS even on? ──────────────────────────────────────────────────
-- If rowsecurity is false for a table, that table is NOT the problem and the
-- policies below are unnecessary for it.
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('children', 'sessions', 'utterances', 'active_sessions');

-- ── Step 1: a kid may read the child row they are linked to ──────────────────
DROP POLICY IF EXISTS "kid reads own child row" ON children;
CREATE POLICY "kid reads own child row"
  ON children FOR SELECT
  TO authenticated
  USING (linked_user_id = auth.uid()::text);

-- ── Step 2: a kid may claim an unclaimed child row while in a live session ───
-- Scoped to children that currently have an active session, so a kid cannot
-- attach themselves to arbitrary profiles.
DROP POLICY IF EXISTS "kid links self during active session" ON children;
CREATE POLICY "kid links self during active session"
  ON children FOR UPDATE
  TO authenticated
  USING (
    linked_user_id IS NULL
    OR linked_user_id = auth.uid()::text
  )
  WITH CHECK (linked_user_id = auth.uid()::text);

-- ── Step 3: a kid may read the sessions of the child they are linked to ──────
DROP POLICY IF EXISTS "kid reads own sessions" ON sessions;
CREATE POLICY "kid reads own sessions"
  ON sessions FOR SELECT
  TO authenticated
  USING (
    child_id IN (
      SELECT id FROM children WHERE linked_user_id = auth.uid()::text
    )
  );

-- ── Step 4: same for utterances, used by the compare screen ──────────────────
DROP POLICY IF EXISTS "kid reads own utterances" ON utterances;
CREATE POLICY "kid reads own utterances"
  ON utterances FOR SELECT
  TO authenticated
  USING (
    session_id IN (
      SELECT s.id FROM sessions s
      JOIN children c ON c.id = s.child_id
      WHERE c.linked_user_id = auth.uid()::text
    )
  );

-- ── Step 5: verify what a kid can now see ────────────────────────────────────
-- Replace <KID_USER_ID> with the kid's auth uid (Supabase > Authentication).
-- Expect one child row and one row per saved session.
-- SELECT id, name, linked_user_id, total_sessions
-- FROM children WHERE linked_user_id = '<KID_USER_ID>';
--
-- SELECT s.id, s.session_number, s.date
-- FROM sessions s JOIN children c ON c.id = s.child_id
-- WHERE c.linked_user_id = '<KID_USER_ID>'
-- ORDER BY s.date DESC;
