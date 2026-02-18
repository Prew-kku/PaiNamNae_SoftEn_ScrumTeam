-- AlterTable
ALTER TABLE "User" ADD COLUMN     "deleteRequestDate" TIMESTAMP(3),
ADD COLUMN     "isDeleteRequested" BOOLEAN NOT NULL DEFAULT false;
