-- =============================================================================
-- Migration: Rename generic PK columns to entity-specific names
-- Database: MySQL (adjust syntax for PostgreSQL if needed -- notes inline)
-- Date: 2026-03-16
--
-- ROLLBACK SAFETY: A rollback script is provided at the bottom.
-- Run this inside a transaction where possible and test on a staging DB first.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 0: Verify enum columns are unchanged (sanity check)
-- Expected: user_role values = admin|attendee
--           ticket_status values = active|used|cancelled
--           alert_level values = alert|safe
-- Run these SELECTs before proceeding:
--   SELECT DISTINCT role FROM users;
--   SELECT DISTINCT status FROM tickets;
--   SELECT DISTINCT level FROM alerts;
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1: Drop all FK constraints that reference columns being renamed
--         NOTE: MySQL requires you to know the constraint name.
--         Use: SHOW CREATE TABLE <tablename>; to find exact constraint names.
--         The names below follow SQLAlchemy's auto-generated convention;
--         replace them with the actual names shown by SHOW CREATE TABLE.
-- ─────────────────────────────────────────────────────────────────────────────

-- tickets → references users.id and events.id
ALTER TABLE tickets
    DROP FOREIGN KEY tickets_ibfk_1,   -- user_id -> users.id
    DROP FOREIGN KEY tickets_ibfk_2;   -- event_id -> events.id

-- crowd_verification → references tickets.id and users.id
ALTER TABLE crowd_verification
    DROP FOREIGN KEY crowd_verification_ibfk_1,  -- ticket_id -> tickets.id
    DROP FOREIGN KEY crowd_verification_ibfk_2;  -- verifier_id -> users.id

-- alerts → references events.id
ALTER TABLE alerts
    DROP FOREIGN KEY alerts_ibfk_1;    -- event_id -> events.id

-- audit_logs → references users.id
ALTER TABLE audit_logs
    DROP FOREIGN KEY audit_logs_ibfk_1;  -- user_id -> users.id

-- crowd_points → references events.id
ALTER TABLE crowd_points
    DROP FOREIGN KEY crowd_points_ibfk_1;  -- event_id -> events.id

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2: Rename PK columns on parent tables
-- ─────────────────────────────────────────────────────────────────────────────

-- users: id -> user_id
ALTER TABLE users
    CHANGE COLUMN `id` `user_id` INT NOT NULL AUTO_INCREMENT;

-- events: id -> event_id
ALTER TABLE events
    CHANGE COLUMN `id` `event_id` INT NOT NULL AUTO_INCREMENT;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3: Rename PK column on tickets (child of users/events, parent of crowd_verification)
-- Also rename the FK column that used to hold tickets.id in crowd_verification
-- ─────────────────────────────────────────────────────────────────────────────

-- tickets: id -> ticket_pk_id
ALTER TABLE tickets
    CHANGE COLUMN `id` `ticket_pk_id` INT NOT NULL AUTO_INCREMENT;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4: Rename PK columns on remaining tables
-- ─────────────────────────────────────────────────────────────────────────────

-- alerts: id -> alert_id
ALTER TABLE alerts
    CHANGE COLUMN `id` `alert_id` INT NOT NULL AUTO_INCREMENT;

-- crowd_verification: id -> verification_id, ticket_id -> ticket_pk_id (FK colname)
ALTER TABLE crowd_verification
    CHANGE COLUMN `id` `verification_id` INT NOT NULL AUTO_INCREMENT,
    CHANGE COLUMN `ticket_id` `ticket_pk_id` INT NOT NULL;

-- audit_logs: id -> audit_id
ALTER TABLE audit_logs
    CHANGE COLUMN `id` `audit_id` INT NOT NULL AUTO_INCREMENT;

-- crowd_points: id -> crowd_point_id
ALTER TABLE crowd_points
    CHANGE COLUMN `id` `crowd_point_id` INT NOT NULL AUTO_INCREMENT;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 5: Re-add FK constraints with updated column references
-- ─────────────────────────────────────────────────────────────────────────────

-- tickets → users.user_id
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_user_id
        FOREIGN KEY (user_id) REFERENCES users(user_id);

-- tickets → events.event_id
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_event_id
        FOREIGN KEY (event_id) REFERENCES events(event_id);

-- crowd_verification → tickets.ticket_pk_id
ALTER TABLE crowd_verification
    ADD CONSTRAINT fk_cv_ticket_pk_id
        FOREIGN KEY (ticket_pk_id) REFERENCES tickets(ticket_pk_id);

-- crowd_verification → users.user_id (verifier)
ALTER TABLE crowd_verification
    ADD CONSTRAINT fk_cv_verifier_id
        FOREIGN KEY (verifier_id) REFERENCES users(user_id);

-- alerts → events.event_id
ALTER TABLE alerts
    ADD CONSTRAINT fk_alerts_event_id
        FOREIGN KEY (event_id) REFERENCES events(event_id);

-- audit_logs → users.user_id
ALTER TABLE audit_logs
    ADD CONSTRAINT fk_audit_user_id
        FOREIGN KEY (user_id) REFERENCES users(user_id);

-- crowd_points → events.event_id
ALTER TABLE crowd_points
    ADD CONSTRAINT fk_cp_event_id
        FOREIGN KEY (event_id) REFERENCES events(event_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 6: Post-migration validation queries
-- Run these to confirm row counts and enum values are unchanged.
-- ─────────────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM users;
-- SELECT COUNT(*) FROM events;
-- SELECT COUNT(*) FROM tickets;
-- SELECT COUNT(*) FROM crowd_verification;
-- SELECT COUNT(*) FROM alerts;
-- SELECT COUNT(*) FROM audit_logs;
-- SELECT COUNT(*) FROM crowd_points;
-- SELECT DISTINCT role FROM users;
-- SELECT DISTINCT status FROM tickets;
-- SELECT DISTINCT level FROM alerts;

-- ─────────────────────────────────────────────────────────────────────────────
-- ROLLBACK SCRIPT (run only if migration fails or needs reverting)
-- ─────────────────────────────────────────────────────────────────────────────
-- -- 1. Drop re-added FK constraints
-- ALTER TABLE tickets         DROP FOREIGN KEY fk_tickets_user_id, DROP FOREIGN KEY fk_tickets_event_id;
-- ALTER TABLE crowd_verification DROP FOREIGN KEY fk_cv_ticket_pk_id, DROP FOREIGN KEY fk_cv_verifier_id;
-- ALTER TABLE alerts          DROP FOREIGN KEY fk_alerts_event_id;
-- ALTER TABLE audit_logs      DROP FOREIGN KEY fk_audit_user_id;
-- ALTER TABLE crowd_points    DROP FOREIGN KEY fk_cp_event_id;
--
-- -- 2. Restore PK column names
-- ALTER TABLE users              CHANGE COLUMN `user_id`       `id`        INT NOT NULL AUTO_INCREMENT;
-- ALTER TABLE events             CHANGE COLUMN `event_id`      `id`        INT NOT NULL AUTO_INCREMENT;
-- ALTER TABLE tickets            CHANGE COLUMN `ticket_pk_id`  `id`        INT NOT NULL AUTO_INCREMENT;
-- ALTER TABLE alerts             CHANGE COLUMN `alert_id`      `id`        INT NOT NULL AUTO_INCREMENT;
-- ALTER TABLE crowd_verification CHANGE COLUMN `verification_id` `id`      INT NOT NULL AUTO_INCREMENT,
--                                CHANGE COLUMN `ticket_pk_id`  `ticket_id` INT NOT NULL;
-- ALTER TABLE audit_logs         CHANGE COLUMN `audit_id`      `id`        INT NOT NULL AUTO_INCREMENT;
-- ALTER TABLE crowd_points       CHANGE COLUMN `crowd_point_id` `id`       INT NOT NULL AUTO_INCREMENT;
--
-- -- 3. Restore original FK constraints (use original auto-generated names or omit names)
-- ALTER TABLE tickets            ADD FOREIGN KEY (user_id)    REFERENCES users(id);
-- ALTER TABLE tickets            ADD FOREIGN KEY (event_id)   REFERENCES events(id);
-- ALTER TABLE crowd_verification ADD FOREIGN KEY (ticket_id)  REFERENCES tickets(id);
-- ALTER TABLE crowd_verification ADD FOREIGN KEY (verifier_id) REFERENCES users(id);
-- ALTER TABLE alerts             ADD FOREIGN KEY (event_id)   REFERENCES events(id);
-- ALTER TABLE audit_logs         ADD FOREIGN KEY (user_id)    REFERENCES users(id);
-- ALTER TABLE crowd_points       ADD FOREIGN KEY (event_id)   REFERENCES events(id);
