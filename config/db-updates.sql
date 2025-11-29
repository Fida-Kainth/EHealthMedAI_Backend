-- Additional schema updates for authentication and advanced features

-- Add password reset token fields to users table (if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='reset_token') THEN
        ALTER TABLE users ADD COLUMN reset_token VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='reset_token_expires') THEN
        ALTER TABLE users ADD COLUMN reset_token_expires TIMESTAMP;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='google_id') THEN
        ALTER TABLE users ADD COLUMN google_id VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='google_email') THEN
        ALTER TABLE users ADD COLUMN google_email VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='avatar_url') THEN
        ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='organization_id') THEN
        ALTER TABLE users ADD COLUMN organization_id INTEGER REFERENCES organizations(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='stakeholder_types') THEN
        ALTER TABLE users ADD COLUMN stakeholder_types TEXT[];
    END IF;
END $$;

-- Add organization_id to ai_agents if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='organization_id') THEN
        ALTER TABLE ai_agents ADD COLUMN organization_id INTEGER REFERENCES organizations(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='voice_model') THEN
        ALTER TABLE ai_agents ADD COLUMN voice_model VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='voice_settings') THEN
        ALTER TABLE ai_agents ADD COLUMN voice_settings JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='system_prompt') THEN
        ALTER TABLE ai_agents ADD COLUMN system_prompt TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='temperature') THEN
        ALTER TABLE ai_agents ADD COLUMN temperature NUMERIC(3,2) DEFAULT 0.7;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='max_tokens') THEN
        ALTER TABLE ai_agents ADD COLUMN max_tokens INTEGER DEFAULT 1000;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='phone_number_id') THEN
        ALTER TABLE ai_agents ADD COLUMN phone_number_id INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='greeting_message') THEN
        ALTER TABLE ai_agents ADD COLUMN greeting_message TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='fallback_message') THEN
        ALTER TABLE ai_agents ADD COLUMN fallback_message TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='business_hours') THEN
        ALTER TABLE ai_agents ADD COLUMN business_hours JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='ai_agents' AND column_name='escalation_rules') THEN
        ALTER TABLE ai_agents ADD COLUMN escalation_rules JSONB;
    END IF;
END $$;

-- Create indexes for reset tokens (if not exists)
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);
CREATE INDEX IF NOT EXISTS idx_ai_agents_organization_id ON ai_agents(organization_id);
