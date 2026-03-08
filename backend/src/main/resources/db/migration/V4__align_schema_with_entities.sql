-- V4: Align schema with current JPA entities
-- - service_requests: deadline column names + SLA breach flag
-- - sla_policies: hour-based columns expected by current model

-- service_requests: rename legacy deadline columns if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'service_requests'
          AND column_name = 'response_sla_deadline'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'service_requests'
          AND column_name = 'response_due_at'
    ) THEN
        ALTER TABLE service_requests RENAME COLUMN response_sla_deadline TO response_due_at;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'service_requests'
          AND column_name = 'resolution_sla_deadline'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'service_requests'
          AND column_name = 'resolution_due_at'
    ) THEN
        ALTER TABLE service_requests RENAME COLUMN resolution_sla_deadline TO resolution_due_at;
    END IF;
END
$$;

ALTER TABLE service_requests
    ADD COLUMN IF NOT EXISTS is_sla_breached BOOLEAN NOT NULL DEFAULT FALSE;

-- sla_policies: add hour columns expected by the entity
ALTER TABLE sla_policies
    ADD COLUMN IF NOT EXISTS response_time_hours INT;

ALTER TABLE sla_policies
    ADD COLUMN IF NOT EXISTS resolution_time_hours INT;

-- Convert legacy minute values to hours (rounding up to preserve intent)
UPDATE sla_policies
SET response_time_hours = GREATEST(1, CEIL(response_time_minutes / 60.0)::INT)
WHERE response_time_hours IS NULL
  AND response_time_minutes IS NOT NULL;

UPDATE sla_policies
SET resolution_time_hours = GREATEST(1, CEIL(resolution_time_minutes / 60.0)::INT)
WHERE resolution_time_hours IS NULL
  AND resolution_time_minutes IS NOT NULL;

-- Finalize nullability expected by JPA mappings
ALTER TABLE sla_policies
    ALTER COLUMN response_time_hours SET NOT NULL;

ALTER TABLE sla_policies
    ALTER COLUMN resolution_time_hours SET NOT NULL;

-- Enforce logical ordering for hour-based columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_resolution_hours_gte_response_hours'
    ) THEN
        ALTER TABLE sla_policies
            ADD CONSTRAINT chk_resolution_hours_gte_response_hours
            CHECK (resolution_time_hours >= response_time_hours);
    END IF;
END
$$;
