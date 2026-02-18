-- Add cancelled status for deletion request audit retention
ALTER TYPE "DeletionStatus" ADD VALUE IF NOT EXISTS 'CANCELLED';
