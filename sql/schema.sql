-- =====================================================================
-- Secure Lead Intake – database schema (RECONSTRUCTED)
--
-- NOTE: This file was reconstructed from the SQL queries used in the
-- n8n workflows and from the project documentation. It is NOT a direct
-- export of the original Neon database. Column types and defaults are
-- reasonable assumptions; the original may differ in details.
--
-- No passwords are stored here. Set role passwords separately, e.g.
--   ALTER ROLE n8n_lead_app WITH PASSWORD '...';
-- and never commit them.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.lead_requests (
    id                  BIGSERIAL PRIMARY KEY,
    customer_name       TEXT        NOT NULL,
    customer_email      TEXT        NOT NULL,
    request_details     TEXT        NOT NULL,

    -- JSON string: ["<lower-cased e-mail>", "<trimmed message>"]
    -- Database-level duplicate protection (INSERT ... ON CONFLICT DO NOTHING)
    dedupe_key          TEXT        NOT NULL UNIQUE,

    status              TEXT        NOT NULL DEFAULT 'new',
    notification_status TEXT        NOT NULL DEFAULT 'pending'
        CHECK (notification_status IN ('pending', 'sent', 'failed')),

    -- Set by the Notification Monitor after a Discord alert was sent
    alert_sent_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- Least-privilege roles
-- ---------------------------------------------------------------------

-- Used by the n8n workflows: read, insert, update – no DELETE, no CREATE
CREATE ROLE n8n_lead_app LOGIN;
GRANT USAGE ON SCHEMA public TO n8n_lead_app;
GRANT SELECT, INSERT, UPDATE ON public.lead_requests TO n8n_lead_app;
GRANT USAGE ON SEQUENCE public.lead_requests_id_seq TO n8n_lead_app;

-- Used by the Appsmith internal UI: read-only
CREATE ROLE appsmith_lead_reader LOGIN;
GRANT USAGE ON SCHEMA public TO appsmith_lead_reader;
GRANT SELECT ON public.lead_requests TO appsmith_lead_reader;

-- Example permission check. A similar "SecurityCheck" query run from Appsmith
-- returned can_insert = false, can_update = false, can_delete = false.
-- SELECT
--   has_table_privilege('appsmith_lead_reader', 'public.lead_requests', 'INSERT') AS can_insert,
--   has_table_privilege('appsmith_lead_reader', 'public.lead_requests', 'UPDATE') AS can_update,
--   has_table_privilege('appsmith_lead_reader', 'public.lead_requests', 'DELETE') AS can_delete;
