-- EHealth Med AI Complete Database Schema
-- This schema includes all tables from the production database

-- Organizations table (must be first due to foreign keys)
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(100) UNIQUE,
    domain VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    subscription_tier VARCHAR(50) DEFAULT 'starter',
    max_agents INTEGER DEFAULT 5,
    max_users INTEGER DEFAULT 10,
    max_calls_per_month INTEGER DEFAULT 1000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMP,
    google_id VARCHAR(255),
    google_email VARCHAR(255),
    avatar_url VARCHAR(500),
    organization_id INTEGER REFERENCES organizations(id),
    stakeholder_types TEXT[]
);

-- Phone Numbers table
CREATE TABLE IF NOT EXISTS phone_numbers (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    phone_number VARCHAR(20) NOT NULL,
    provider VARCHAR(50),
    provider_sid VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    capabilities JSONB,
    monthly_cost NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI Voice Agents table
CREATE TABLE IF NOT EXISTS ai_agents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    configuration JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    organization_id INTEGER REFERENCES organizations(id),
    voice_model VARCHAR(100),
    voice_settings JSONB,
    system_prompt TEXT,
    temperature NUMERIC(3,2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 1000,
    phone_number_id INTEGER REFERENCES phone_numbers(id),
    greeting_message TEXT,
    fallback_message TEXT,
    business_hours JSONB,
    escalation_rules JSONB
);

-- Conversations/Interactions table
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    agent_id INTEGER REFERENCES ai_agents(id),
    patient_name VARCHAR(255),
    patient_phone VARCHAR(20),
    status VARCHAR(50) DEFAULT 'active',
    transcript JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id),
    patient_name VARCHAR(255) NOT NULL,
    patient_phone VARCHAR(20),
    patient_email VARCHAR(255),
    appointment_date TIMESTAMP NOT NULL,
    appointment_type VARCHAR(100),
    status VARCHAR(50) DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log for HIPAA compliance
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id INTEGER,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Integrations table
CREATE TABLE IF NOT EXISTS integrations (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    provider VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    credentials JSONB,
    config JSONB,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL
);

-- Role Permissions table
CREATE TABLE IF NOT EXISTS role_permissions (
    id SERIAL PRIMARY KEY,
    role VARCHAR(50) NOT NULL,
    permission_id INTEGER REFERENCES permissions(id),
    UNIQUE(role, permission_id)
);

-- Access Policies table
CREATE TABLE IF NOT EXISTS access_policies (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id INTEGER,
    role VARCHAR(50),
    permissions TEXT[],
    conditions JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- API Keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    key_prefix VARCHAR(20) NOT NULL,
    permissions TEXT[],
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Call Logs table
CREATE TABLE IF NOT EXISTS call_logs (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    phone_number_id INTEGER REFERENCES phone_numbers(id),
    agent_id INTEGER REFERENCES ai_agents(id),
    conversation_id INTEGER REFERENCES conversations(id),
    caller_phone VARCHAR(20),
    caller_name VARCHAR(255),
    direction VARCHAR(10),
    status VARCHAR(50),
    duration_seconds INTEGER,
    recording_url VARCHAR(500),
    transcription_text TEXT,
    cost NUMERIC(10,4),
    provider_call_id VARCHAR(255),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Encryption Keys table
CREATE TABLE IF NOT EXISTS encryption_keys (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    key_name VARCHAR(255) NOT NULL,
    key_type VARCHAR(50),
    algorithm VARCHAR(50) DEFAULT 'AES-256',
    key_encrypted TEXT NOT NULL,
    rotation_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Call Recordings table
CREATE TABLE IF NOT EXISTS call_recordings (
    id SERIAL PRIMARY KEY,
    call_log_id INTEGER REFERENCES call_logs(id),
    organization_id INTEGER REFERENCES organizations(id),
    recording_url VARCHAR(500) NOT NULL,
    storage_provider VARCHAR(50),
    storage_path VARCHAR(500),
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    format VARCHAR(20) DEFAULT 'mp3',
    encryption_key_id INTEGER REFERENCES encryption_keys(id),
    retention_until TIMESTAMP,
    is_encrypted BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Call Metrics table
CREATE TABLE IF NOT EXISTS call_metrics (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    agent_id INTEGER REFERENCES ai_agents(id),
    date DATE NOT NULL,
    total_calls INTEGER DEFAULT 0,
    completed_calls INTEGER DEFAULT 0,
    failed_calls INTEGER DEFAULT 0,
    total_duration_seconds INTEGER DEFAULT 0,
    avg_duration_seconds NUMERIC(10,2),
    total_cost NUMERIC(10,2) DEFAULT 0,
    satisfaction_score NUMERIC(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, agent_id, date)
);

-- Agent Performance table
CREATE TABLE IF NOT EXISTS agent_performance (
    id SERIAL PRIMARY KEY,
    agent_id INTEGER REFERENCES ai_agents(id),
    organization_id INTEGER REFERENCES organizations(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_interactions INTEGER DEFAULT 0,
    successful_interactions INTEGER DEFAULT 0,
    avg_response_time_seconds NUMERIC(10,2),
    avg_satisfaction_score NUMERIC(3,2),
    escalation_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stakeholder Types table
CREATE TABLE IF NOT EXISTS stakeholder_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    reading_guidance TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Terminology table
CREATE TABLE IF NOT EXISTS terminology (
    id SERIAL PRIMARY KEY,
    term VARCHAR(255) UNIQUE NOT NULL,
    acronym VARCHAR(50),
    definition TEXT NOT NULL,
    category VARCHAR(100),
    related_terms INTEGER[],
    reference_urls TEXT[],
    stakeholder_relevance TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reference Standards table
CREATE TABLE IF NOT EXISTS reference_standards (
    id SERIAL PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    description TEXT,
    authority VARCHAR(255),
    version VARCHAR(50),
    document_url VARCHAR(500),
    applicable_sections TEXT[],
    stakeholder_relevance TEXT[],
    compliance_requirements TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Requirements table
CREATE TABLE IF NOT EXISTS requirements (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    requirement_id VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requirement_type VARCHAR(20) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'draft',
    related_constraints INTEGER[],
    related_assumptions INTEGER[],
    parent_requirement_id INTEGER REFERENCES requirements(id),
    implementation_notes TEXT,
    verification_criteria TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP,
    verified_by INTEGER REFERENCES users(id)
);

-- Operational Assumptions table
CREATE TABLE IF NOT EXISTS operational_assumptions (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    assumption_id VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    impact_level VARCHAR(20) DEFAULT 'medium',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Constraints table
CREATE TABLE IF NOT EXISTS constraints (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    constraint_id VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    constraint_type VARCHAR(50) NOT NULL,
    enforcement_level VARCHAR(20) DEFAULT 'mandatory',
    validation_rule JSONB,
    is_enforced BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Deliverables table
CREATE TABLE IF NOT EXISTS deliverables (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER REFERENCES organizations(id),
    deliverable_id VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'planned',
    assigned_to INTEGER REFERENCES users(id),
    due_date DATE,
    completed_date DATE,
    dependencies INTEGER[],
    related_requirements INTEGER[],
    related_documents INTEGER[],
    acceptance_criteria TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

CREATE INDEX IF NOT EXISTS idx_ai_agents_type ON ai_agents(type);
CREATE INDEX IF NOT EXISTS idx_ai_agents_organization_id ON ai_agents(organization_id);

CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_agent_id ON conversations(agent_id);

CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_phone_numbers_organization_id ON phone_numbers(organization_id);

CREATE INDEX IF NOT EXISTS idx_integrations_organization_id ON integrations(organization_id);

CREATE INDEX IF NOT EXISTS idx_access_policies_org ON access_policies(organization_id);

CREATE INDEX IF NOT EXISTS idx_api_keys_organization_id ON api_keys(organization_id);

CREATE INDEX IF NOT EXISTS idx_call_logs_organization_id ON call_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_agent_id ON call_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_call_logs_started_at ON call_logs(started_at);

CREATE INDEX IF NOT EXISTS idx_call_recordings_call_log_id ON call_recordings(call_log_id);

CREATE INDEX IF NOT EXISTS idx_call_metrics_organization_id ON call_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_call_metrics_date ON call_metrics(date);

CREATE INDEX IF NOT EXISTS idx_requirements_org ON requirements(organization_id);
CREATE INDEX IF NOT EXISTS idx_requirements_category ON requirements(category);
CREATE INDEX IF NOT EXISTS idx_requirements_status ON requirements(status);
CREATE INDEX IF NOT EXISTS idx_requirements_type ON requirements(requirement_type);

CREATE INDEX IF NOT EXISTS idx_assumptions_org ON operational_assumptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_assumptions_category ON operational_assumptions(category);

CREATE INDEX IF NOT EXISTS idx_constraints_org ON constraints(organization_id);
CREATE INDEX IF NOT EXISTS idx_constraints_category ON constraints(category);

CREATE INDEX IF NOT EXISTS idx_deliverables_org ON deliverables(organization_id);
CREATE INDEX IF NOT EXISTS idx_deliverables_category ON deliverables(category);
CREATE INDEX IF NOT EXISTS idx_deliverables_status ON deliverables(status);

-- Insert default AI agents (only if they don't exist)
INSERT INTO ai_agents (name, type, description, is_active)
SELECT 'Front Desk Assistant', 'Front Desk Assistant', 'Handles appointment scheduling, patient check-ins, and general inquiries', true
WHERE NOT EXISTS (SELECT 1 FROM ai_agents WHERE name = 'Front Desk Assistant' AND type = 'Front Desk Assistant');

INSERT INTO ai_agents (name, type, description, is_active)
SELECT 'Medical Assistant', 'Medical Assistant', 'Assists with medical information, symptom assessment, and care coordination', true
WHERE NOT EXISTS (SELECT 1 FROM ai_agents WHERE name = 'Medical Assistant' AND type = 'Medical Assistant');

INSERT INTO ai_agents (name, type, description, is_active)
SELECT 'Triage Nurse', 'Triage Nurse', 'Performs initial patient assessment and prioritizes care based on urgency', true
WHERE NOT EXISTS (SELECT 1 FROM ai_agents WHERE name = 'Triage Nurse' AND type = 'Triage Nurse');

INSERT INTO ai_agents (name, type, description, is_active)
SELECT 'Billing Specialist', 'Billing Specialist', 'Manages billing inquiries, payment processing, and insurance questions', true
WHERE NOT EXISTS (SELECT 1 FROM ai_agents WHERE name = 'Billing Specialist' AND type = 'Billing Specialist');

INSERT INTO ai_agents (name, type, description, is_active)
SELECT 'Collections Specialist', 'Collections Specialist', 'Handles payment collections and payment plan arrangements', true
WHERE NOT EXISTS (SELECT 1 FROM ai_agents WHERE name = 'Collections Specialist' AND type = 'Collections Specialist');
