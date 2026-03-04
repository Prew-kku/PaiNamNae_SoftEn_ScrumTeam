-- CreateTable
CREATE TABLE "UserDeletionLog" (
    "id" TEXT NOT NULL,
    "targetUserId" TEXT NOT NULL,
    "targetEmail" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "deletedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedBy" TEXT,

    CONSTRAINT "UserDeletionLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "UserDeletionLog_deletedAt_idx" ON "UserDeletionLog"("deletedAt");
