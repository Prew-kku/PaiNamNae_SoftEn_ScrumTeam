/*
  Warnings:

  - You are about to drop the `DeleteRequest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Reason` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `UserDeletionLog` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "DeleteRequest" DROP CONSTRAINT "DeleteRequest_reasonId_fkey";

-- DropForeignKey
ALTER TABLE "DeleteRequest" DROP CONSTRAINT "DeleteRequest_userId_fkey";

-- DropTable
DROP TABLE "DeleteRequest";

-- DropTable
DROP TABLE "Reason";

-- DropTable
DROP TABLE "UserDeletionLog";

-- DropEnum
DROP TYPE "DeleteRequestStatus";
