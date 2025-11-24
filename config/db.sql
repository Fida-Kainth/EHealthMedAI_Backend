-- EHealth Med AI Database Schema

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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent Types: Front Desk Assistant, Medical Assistant, Triage Nurse, Billing Specialist, Collections Specialist

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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_ai_agents_type ON ai_agents(type);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_agent_id ON conversations(agent_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

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

