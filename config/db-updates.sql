-- Additional schema updates for authentication and advanced features
-- Note: These use individual ALTER TABLE statements that are safe to re-run

-- Add columns to users table (will fail silently if they exist)
-- Using separate statements for compatibility with the migration parser

ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_email VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500);
ALTER TABLE users ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS stakeholder_types TEXT[];

-- Add columns to ai_agents table
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS organization_id INTEGER;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS voice_model VARCHAR(100);
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS voice_settings JSONB;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS system_prompt TEXT;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS temperature NUMERIC(3,2) DEFAULT 0.7;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS max_tokens INTEGER DEFAULT 1000;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS phone_number_id INTEGER;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS greeting_message TEXT;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS fallback_message TEXT;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS business_hours JSONB;
ALTER TABLE ai_agents ADD COLUMN IF NOT EXISTS escalation_rules JSONB;

-- Add foreign key constraints (will fail if already exists, which is fine)
-- Note: These may error if constraint already exists, but won't break anything

-- Create indexes (IF NOT EXISTS makes these safe)
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);
CREATE INDEX IF NOT EXISTS idx_ai_agents_organization_id ON ai_agents(organization_id);
