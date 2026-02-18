-- Add cancelled status for deletion request audit retention
ALTER TYPE "DeletionStatus" ADD VALUE IF NOT EXISTS 'CANCELLED';
ALTER TYPE "DeletionStatus" ADD VALUE IF NOT EXISTS 'DELETED';

DO $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DeletionAuditStatus') THEN
		CREATE TYPE "DeletionAuditStatus" AS ENUM ('REQUESTED', 'CANCELLED', 'APPROVED', 'REJECTED', 'ANONYMIZED', 'DELETED');
	END IF;
END $$;

-- Allow multiple deletion requests per user (history rows)
ALTER TABLE "DeletionRequest" DROP CONSTRAINT IF EXISTS "DeletionRequest_userId_key";

CREATE INDEX IF NOT EXISTS "DeletionRequest_userId_idx" ON "DeletionRequest"("userId");
CREATE INDEX IF NOT EXISTS "DeletionRequest_userId_status_idx" ON "DeletionRequest"("userId", "status");
CREATE INDEX IF NOT EXISTS "DeletionRequest_requestedAt_idx" ON "DeletionRequest"("requestedAt");

ALTER TABLE "DeletionAudit" ADD COLUMN IF NOT EXISTS "requestId" TEXT;
ALTER TABLE "DeletionAudit" ADD COLUMN IF NOT EXISTS "eventTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
	IF EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_name = 'DeletionAudit' AND column_name = 'status'
	) THEN
		ALTER TABLE "DeletionAudit"
			ALTER COLUMN "status" TYPE "DeletionAuditStatus"
			USING CASE
				WHEN "status" IN ('REQUESTED', 'CANCELLED', 'APPROVED', 'REJECTED', 'ANONYMIZED', 'DELETED')
					THEN "status"::"DeletionAuditStatus"
				WHEN "status" = 'COMPLETED'
					THEN 'ANONYMIZED'::"DeletionAuditStatus"
				ELSE 'REQUESTED'::"DeletionAuditStatus"
			END;
	END IF;
END $$;

ALTER TABLE "DeletionAudit" ALTER COLUMN "status" SET NOT NULL;

ALTER TABLE "DeletionAudit"
	ADD CONSTRAINT "DeletionAudit_requestId_fkey"
	FOREIGN KEY ("requestId") REFERENCES "DeletionRequest"("id")
	ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "DeletionAudit_requestId_idx" ON "DeletionAudit"("requestId");
CREATE INDEX IF NOT EXISTS "DeletionAudit_status_idx" ON "DeletionAudit"("status");
CREATE INDEX IF NOT EXISTS "DeletionAudit_eventTime_idx" ON "DeletionAudit"("eventTime");
