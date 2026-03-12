-- ============================================
-- DENTAL CLINIC AUTOMATION - COMPLETE DATABASE
-- ============================================
-- Version: 1.0
-- For: n8n Workflow Automation Kit
-- Includes: Patients, Appointments, Quotes, Payments
-- ============================================

-- Drop existing tables (optional - remove if keeping existing data)
DROP TABLE IF EXISTS message_logs CASCADE;
DROP TABLE IF EXISTS payment_plans CASCADE;
DROP TABLE IF EXISTS quotes CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS clinics CASCADE;
DROP TABLE IF EXISTS treatments CASCADE;

-- ============================================
-- 1. CLINICS TABLE (Multi-clinic Support)
-- ============================================
CREATE TABLE clinics (
  clinic_id SERIAL PRIMARY KEY,
  clinic_name VARCHAR(100) NOT NULL,
  clinic_address TEXT,
  clinic_phone VARCHAR(20),
  whatsapp_number VARCHAR(20),
  whatsapp_business_id VARCHAR(100),
  whatsapp_access_token TEXT,
  sms_number VARCHAR(20),
  sms_provider VARCHAR(50), -- 'twilio', 'africastalking', etc.
  sms_api_key TEXT,
  email_address VARCHAR(100),
  payment_instructions TEXT,
  emergency_contact_phone VARCHAR(20),
  payment_gateway_config JSONB DEFAULT '{}',
  timezone VARCHAR(50) DEFAULT 'Africa/Kampala',
  business_hours JSONB DEFAULT '{"mon": "8:00-17:00", "tue": "8:00-17:00", "wed": "8:00-17:00", "thu": "8:00-17:00", "fri": "8:00-17:00", "sat": "9:00-13:00"}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 2. PATIENTS TABLE (Master Patient Records)
-- ============================================
CREATE TABLE patients (
  patient_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_code VARCHAR(20) UNIQUE NOT NULL, -- Format: CLINIC-YEAR-0001
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  date_of_birth DATE,
  gender VARCHAR(10), -- 'male', 'female', 'other'
  patient_phone VARCHAR(20) NOT NULL,
  patient_phone_2 VARCHAR(20),
  patient_email VARCHAR(100),
  address TEXT,
  occupation VARCHAR(100),
  emergency_contact_name VARCHAR(100),
  emergency_contact_phone VARCHAR(20),
  medical_conditions TEXT,
  allergies TEXT,
  preferred_language VARCHAR(50) DEFAULT 'English',
  communication_preference VARCHAR(20) DEFAULT 'whatsapp', -- 'whatsapp', 'sms', 'email', 'call'
  consent_marketing BOOLEAN DEFAULT true,
  consent_data_processing BOOLEAN DEFAULT true,
  patient_notes TEXT,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'blocked'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_patient_clinic (clinic_id),
  INDEX idx_patient_phone (patient_phone)
);

-- ============================================
-- 3. TREATMENTS CATALOG (Standard Treatments)
-- ============================================
CREATE TABLE treatments (
  treatment_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  treatment_code VARCHAR(20) NOT NULL,
  treatment_name VARCHAR(200) NOT NULL,
  treatment_category VARCHAR(100), -- 'preventive', 'restorative', 'cosmetic', 'surgical'
  description TEXT,
  default_duration_minutes INTEGER DEFAULT 30,
  default_price DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'UGX',
  is_active BOOLEAN DEFAULT true,
  requires_specialist BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(clinic_id, treatment_code),
  INDEX idx_treatment_clinic (clinic_id)
);

-- ============================================
-- 4. APPOINTMENTS TABLE (Workflow 1)
-- ============================================
CREATE TABLE appointments (
  appointment_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_id INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  treatment_id INTEGER REFERENCES treatments(treatment_id),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  appointment_datetime TIMESTAMP GENERATED ALWAYS AS (appointment_date + appointment_time) STORED,
  appointment_type VARCHAR(50), -- 'consultation', 'treatment', 'followup', 'emergency'
  treatment_description TEXT,
  dentist_id INTEGER, -- Could reference a dentists table
  dentist_name VARCHAR(100),
  room_number VARCHAR(20),
  duration_minutes INTEGER DEFAULT 30,
  status VARCHAR(20) DEFAULT 'scheduled', -- 'scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'
  appointment_notes TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  reminder_sent_at TIMESTAMP,
  reminder_count INTEGER DEFAULT 0,
  reminder_method VARCHAR(20) DEFAULT 'whatsapp', -- 'whatsapp', 'sms', 'email'
  confirmation_received BOOLEAN DEFAULT false,
  confirmed_at TIMESTAMP,
  cancellation_reason TEXT,
  created_by INTEGER, -- staff_id
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_appointment_datetime (appointment_datetime),
  INDEX idx_appointment_status (status),
  INDEX idx_appointment_clinic (clinic_id),
  INDEX idx_appointment_patient (patient_id)
);

-- ============================================
-- 5. QUOTES TABLE (Workflow 2)
-- ============================================
CREATE TABLE quotes (
  quote_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_id INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  quote_number VARCHAR(50) UNIQUE NOT NULL, -- Format: Q-2024-001
  patient_name VARCHAR(100) NOT NULL,
  patient_phone VARCHAR(20) NOT NULL,
  quote_amount DECIMAL(12,2) NOT NULL,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) GENERATED ALWAYS AS (quote_amount + tax_amount) STORED,
  currency VARCHAR(3) DEFAULT 'UGX',
  treatment_description TEXT NOT NULL,
  treatment_breakdown JSONB DEFAULT '[]', -- Array of treatment items
  valid_until DATE,
  payment_terms TEXT,
  status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'sent', 'considering', 'accepted', 'rejected', 'expired'
  followup_stage INTEGER DEFAULT 0, -- 0=no followups, 1=first sent, 2=second sent, 3=third sent
  last_followup_date TIMESTAMP,
  followup_count INTEGER DEFAULT 0,
  next_followup_date DATE,
  conversion_date TIMESTAMP, -- When quote became appointment
  appointment_id INTEGER REFERENCES appointments(appointment_id),
  closed_reason VARCHAR(100),
  created_by INTEGER, -- staff_id
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_quote_status (status),
  INDEX idx_quote_clinic (clinic_id),
  INDEX idx_quote_patient (patient_id),
  INDEX idx_quote_followup (next_followup_date)
);

-- ============================================
-- 6. PAYMENT PLANS TABLE (Workflow 3)
-- ============================================
CREATE TABLE payment_plans (
  payment_plan_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_id INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  quote_id INTEGER REFERENCES quotes(quote_id),
  appointment_id INTEGER REFERENCES appointments(appointment_id),
  plan_number VARCHAR(50) UNIQUE NOT NULL, -- Format: PP-2024-001
  plan_name VARCHAR(200),
  procedure_name VARCHAR(200) NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  amount_paid DECIMAL(12,2) DEFAULT 0,
  balance_due DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
  initial_deposit DECIMAL(12,2) DEFAULT 0,
  installment_count INTEGER NOT NULL,
  next_payment_due DATE NOT NULL,
  next_payment_amount DECIMAL(12,2) NOT NULL,
  payment_frequency VARCHAR(20) DEFAULT 'monthly', -- 'weekly', 'biweekly', 'monthly', 'custom'
  payment_method VARCHAR(50), -- 'cash', 'mobile_money', 'bank_transfer', 'credit_card'
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'overdue', 'defaulted', 'cancelled'
  start_date DATE NOT NULL,
  expected_end_date DATE,
  actual_end_date DATE,
  payments_made INTEGER DEFAULT 0,
  payments_missed INTEGER DEFAULT 0,
  grace_period_days INTEGER DEFAULT 3,
  last_reminder_sent TIMESTAMP,
  reminder_count INTEGER DEFAULT 0,
  default_reason TEXT,
  created_by INTEGER, -- staff_id
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_plan_status (status),
  INDEX idx_payment_due (next_payment_due),
  INDEX idx_payment_clinic (clinic_id),
  INDEX idx_payment_patient (patient_id)
);

-- ============================================
-- 7. PAYMENTS TABLE (Transaction Records)
-- ============================================
CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_id INTEGER NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
  payment_plan_id INTEGER REFERENCES payment_plans(payment_plan_id),
  quote_id INTEGER REFERENCES quotes(quote_id),
  appointment_id INTEGER REFERENCES appointments(appointment_id),
  payment_number VARCHAR(50) UNIQUE NOT NULL, -- Format: PAY-2024-001
  payment_date DATE NOT NULL,
  payment_time TIME DEFAULT CURRENT_TIME,
  payment_datetime TIMESTAMP GENERATED ALWAYS AS (payment_date + payment_time) STORED,
  amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'UGX',
  payment_method VARCHAR(50) NOT NULL, -- 'cash', 'mobile_money', 'bank_transfer', 'credit_card'
  payment_reference VARCHAR(100), -- MTN/AIRTEL reference, bank reference
  payment_channel VARCHAR(50), -- 'mtn_momo', 'airtel_money', 'bank_deposit'
  transaction_id VARCHAR(100),
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  confirmed_by INTEGER, -- staff_id
  confirmed_at TIMESTAMP,
  notes TEXT,
  receipt_issued BOOLEAN DEFAULT false,
  receipt_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_date (payment_date),
  INDEX idx_payment_status (status),
  INDEX idx_payment_clinic (clinic_id),
  INDEX idx_payment_patient (patient_id)
);

-- ============================================
-- 8. MESSAGE LOGS TABLE (All Communications)
-- ============================================
CREATE TABLE message_logs (
  log_id SERIAL PRIMARY KEY,
  clinic_id INTEGER NOT NULL REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  patient_id INTEGER REFERENCES patients(patient_id) ON DELETE SET NULL,
  workflow_type VARCHAR(50) NOT NULL, -- 'appointment_reminder', 'quote_followup', 'payment_reminder'
  message_type VARCHAR(50) NOT NULL, -- 'whatsapp', 'sms', 'email'
  template_name VARCHAR(100),
  recipient_name VARCHAR(100),
  recipient_phone VARCHAR(20) NOT NULL,
  recipient_email VARCHAR(100),
  message_subject VARCHAR(200),
  message_body TEXT NOT NULL,
  message_variables JSONB DEFAULT '{}', -- Variables used in template
  scheduled_for TIMESTAMP,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'sent', -- 'queued', 'sent', 'delivered', 'read', 'failed'
  error_message TEXT,
  provider_response JSONB DEFAULT '{}', -- Raw response from WhatsApp/SMS provider
  external_message_id VARCHAR(100), -- Provider's message ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_message_sent (sent_at),
  INDEX idx_message_status (status),
  INDEX idx_message_clinic (clinic_id),
  INDEX idx_message_patient (patient_id),
  INDEX idx_message_workflow (workflow_type)
);

-- ============================================
-- 9. AUTOMATION LOGS (Workflow Execution Logs)
-- ============================================
CREATE TABLE automation_logs (
  log_id SERIAL PRIMARY KEY,
  clinic_id INTEGER REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  workflow_name VARCHAR(100) NOT NULL,
  execution_id VARCHAR(100) NOT NULL,
  trigger_type VARCHAR(50), -- 'cron', 'webhook', 'manual'
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  duration_ms INTEGER,
  records_processed INTEGER DEFAULT 0,
  messages_sent INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'running', -- 'running', 'completed', 'failed', 'partial'
  error_details TEXT,
  summary JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_automation_time (start_time),
  INDEX idx_automation_workflow (workflow_name),
  INDEX idx_automation_clinic (clinic_id)
);

-- ============================================
-- TRIGGERS for updated_at timestamps
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all main tables
CREATE TRIGGER update_clinics_updated_at BEFORE UPDATE ON clinics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_treatments_updated_at BEFORE UPDATE ON treatments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_plans_updated_at BEFORE UPDATE ON payment_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert sample clinics
INSERT INTO clinics (clinic_id, clinic_name, whatsapp_number, sms_number, payment_instructions, emergency_contact_phone) VALUES
(1, 'Kampala Dental Center', '+256700123456', '+256700123456', 'Mobile Money: 0783123456 (John) or Centenary Bank A/C 123456789', '+256772123456'),
(2, 'Entebbe Dental Care', '+256700123457', '+256700123457', 'Airtel Money: 0755123456 or Stanbic Bank A/C 987654321', '+256772123457'),
(3, 'Jinja Smile Clinic', '+256700123458', '+256700123458', 'MTN Mobile Money: 0777123456 or Bank of Africa A/C 456789123', '+256772123458')
ON CONFLICT (clinic_id) DO UPDATE SET
  clinic_name = EXCLUDED.clinic_name,
  whatsapp_number = EXCLUDED.whatsapp_number,
  payment_instructions = EXCLUDED.payment_instructions;

-- Insert sample patients
INSERT INTO patients (clinic_id, patient_code, first_name, last_name, patient_phone, date_of_birth, gender) VALUES
(1, 'KDC-2024-0001', 'John', 'Doe', '+256700111111', '1985-06-15', 'male'),
(1, 'KDC-2024-0002', 'Jane', 'Smith', '+256700222222', '1990-03-22', 'female'),
(2, 'EDC-2024-0001', 'Robert', 'Johnson', '+256700333333', '1978-11-30', 'male'),
(3, 'JSC-2024-0001', 'Mary', 'Williams', '+256700444444', '1995-08-14', 'female')
ON CONFLICT (patient_code) DO NOTHING;

-- Insert sample treatments
INSERT INTO treatments (clinic_id, treatment_code, treatment_name, treatment_category, default_price, description) VALUES
(1, 'DC001', 'Dental Implant', 'surgical', 5000000, 'Single tooth implant with crown'),
(1, 'DC002', 'Teeth Whitening', 'cosmetic', 850000, 'Professional in-office whitening'),
(1, 'DC003', 'Root Canal', 'restorative', 1200000, 'Single canal root canal treatment'),
(2, 'EDC001', 'Dental Cleaning', 'preventive', 250000, 'Professional dental cleaning'),
(3, 'JSC001', 'Braces Consultation', 'cosmetic', 150000, 'Initial consultation for braces')
ON CONFLICT DO NOTHING;

-- Insert sample appointments
INSERT INTO appointments (clinic_id, patient_id, treatment_id, appointment_date, appointment_time, treatment_description, status) VALUES
(1, 1, 1, CURRENT_DATE + INTERVAL '1 day', '10:00:00', 'Dental Implant - Followup', 'scheduled'),
(1, 2, 2, CURRENT_DATE + INTERVAL '2 days', '14:30:00', 'Teeth Whitening Session', 'scheduled'),
(2, 3, 4, CURRENT_DATE + INTERVAL '3 days', '09:00:00', 'Regular Dental Cleaning', 'scheduled')
ON CONFLICT DO NOTHING;

-- Insert sample quotes
INSERT INTO quotes (clinic_id, patient_id, quote_number, patient_name, patient_phone, quote_amount, treatment_description, status) VALUES
(1, 1, 'Q-2024-001', 'John Doe', '+256700111111', 5000000, 'Dental Implant with Crown', 'considering'),
(1, 2, 'Q-2024-002', 'Jane Smith', '+256700222222', 850000, 'Professional Teeth Whitening', 'considering'),
(2, 3, 'Q-2024-003', 'Robert Johnson', '+256700333333', 250000, 'Dental Cleaning & Checkup', 'sent')
ON CONFLICT (quote_number) DO NOTHING;

-- Insert sample payment plans
INSERT INTO payment_plans (clinic_id, patient_id, plan_number, procedure_name, total_amount, amount_paid, balance_due, installment_count, next_payment_due, next_payment_amount, payment_frequency, status, start_date) VALUES
(1, 1, 'PP-2024-001', 'Dental Implant', 5000000, 2000000, 3000000, 6, CURRENT_DATE + INTERVAL '7 days', 500000, 'monthly', 'active', CURRENT_DATE - INTERVAL '1 month'),
(1, 2, 'PP-2024-002', 'Teeth Whitening', 850000, 425000, 425000, 2, CURRENT_DATE, 425000, 'monthly', 'active', CURRENT_DATE - INTERVAL '15 days'),
(2, 3, 'PP-2024-003', 'Dental Cleaning', 250000, 125000, 125000, 2, CURRENT_DATE + INTERVAL '5 days', 125000, 'weekly', 'active', CURRENT_DATE - INTERVAL '7 days')
ON CONFLICT (plan_number) DO NOTHING;

-- ============================================
-- VIEWS for Reporting
-- ============================================

-- View: Daily appointments overview
CREATE VIEW vw_daily_appointments AS
SELECT 
  a.clinic_id,
  c.clinic_name,
  a.appointment_date,
  COUNT(*) as total_appointments,
  COUNT(CASE WHEN a.status = 'scheduled' THEN 1 END) as scheduled,
  COUNT(CASE WHEN a.status = 'confirmed' THEN 1 END) as confirmed,
  COUNT(CASE WHEN a.status = 'completed' THEN 1 END) as completed,
  COUNT(CASE WHEN a.reminder_sent = true THEN 1 END) as reminders_sent
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY a.clinic_id, c.clinic_name, a.appointment_date
ORDER BY a.appointment_date DESC;

-- View: Payment plan status
CREATE VIEW vw_payment_plan_status AS
SELECT 
  pp.clinic_id,
  c.clinic_name,
  pp.status as plan_status,
  COUNT(*) as total_plans,
  SUM(pp.total_amount) as total_value,
  SUM(pp.balance_due) as total_balance_due,
  AVG(pp.next_payment_amount) as avg_installment,
  SUM(CASE WHEN pp.next_payment_due < CURRENT_DATE THEN 1 ELSE 0 END) as overdue_plans
FROM payment_plans pp
JOIN clinics c ON pp.clinic_id = c.clinic_id
WHERE pp.status IN ('active', 'overdue')
GROUP BY pp.clinic_id, c.clinic_name, pp.status
ORDER BY pp.clinic_id, pp.status;

-- View: Quote conversion tracking
CREATE VIEW vw_quote_conversion AS
SELECT 
  q.clinic_id,
  c.clinic_name,
  q.status as quote_status,
  COUNT(*) as total_quotes,
  SUM(q.total_amount) as total_quote_value,
  COUNT(CASE WHEN q.appointment_id IS NOT NULL THEN 1 END) as converted_to_appointment,
  ROUND(COUNT(CASE WHEN q.appointment_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as conversion_rate
FROM quotes q
JOIN clinics c ON q.clinic_id = c.clinic_id
GROUP BY q.clinic_id, c.clinic_name, q.status
ORDER BY q.clinic_id, q.status;

-- ============================================
-- FUNCTIONS for automation
-- ============================================

-- Function: Generate next payment date
CREATE OR REPLACE FUNCTION calculate_next_payment(
  current_date DATE,
  frequency VARCHAR(20)
) RETURNS DATE AS $$
BEGIN
  RETURN CASE frequency
    WHEN 'weekly' THEN current_date + INTERVAL '7 days'
    WHEN 'biweekly' THEN current_date + INTERVAL '14 days'
    WHEN 'monthly' THEN current_date + INTERVAL '1 month'
    WHEN 'quarterly' THEN current_date + INTERVAL '3 months'
    ELSE current_date + INTERVAL '30 days' -- Default monthly
  END;
END;
$$ LANGUAGE plpgsql;

-- Function: Update payment plan after payment
CREATE OR REPLACE FUNCTION update_payment_plan_after_payment(
  p_payment_plan_id INTEGER,
  p_payment_amount DECIMAL(12,2)
) RETURNS VOID AS $$
DECLARE
  v_remaining_installments INTEGER;
  v_next_payment_due DATE;
BEGIN
  -- Update amount paid
  UPDATE payment_plans 
  SET 
    amount_paid = amount_paid + p_payment_amount,
    payments_made = payments_made + 1,
    updated_at = CURRENT_TIMESTAMP
  WHERE payment_plan_id = p_payment_plan_id;
  
  -- Check if balance is cleared
  IF (SELECT balance_due FROM payment_plans WHERE payment_plan_id = p_payment_plan_id) <= 0 THEN
    UPDATE payment_plans 
    SET 
      status = 'completed',
      actual_end_date = CURRENT_DATE,
      next_payment_due = NULL,
      updated_at = CURRENT_TIMESTAMP
    WHERE payment_plan_id = p_payment_plan_id;
  ELSE
    -- Calculate next payment date
    SELECT calculate_next_payment(next_payment_due, payment_frequency)
    INTO v_next_payment_due
    FROM payment_plans 
    WHERE payment_plan_id = p_payment_plan_id;
    
    UPDATE payment_plans 
    SET 
      next_payment_due = v_next_payment_due,
      updated_at = CURRENT_TIMESTAMP
    WHERE payment_plan_id = p_payment_plan_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- INDEXES for performance
-- ============================================
CREATE INDEX idx_appointments_composite ON appointments (clinic_id, appointment_date, status);
CREATE INDEX idx_quotes_composite ON quotes (clinic_id, status, next_followup_date);
CREATE INDEX idx_payment_plans_composite ON payment_plans (clinic_id, status, next_payment_due);
CREATE INDEX idx_payments_composite ON payments (clinic_id, payment_date, status);
CREATE INDEX idx_message_logs_composite ON message_logs (clinic_id, sent_at, status);

-- ============================================
-- COMMENTS for documentation
-- ============================================
COMMENT ON TABLE clinics IS 'Stores multi-clinic configuration and credentials';
COMMENT ON TABLE patients IS 'Master patient records for all clinics';
COMMENT ON TABLE appointments IS 'Appointments for workflow 1: Appointment reminders';
COMMENT ON TABLE quotes IS 'Quotes for workflow 2: Quote follow-up automation';
COMMENT ON TABLE payment_plans IS 'Payment plans for workflow 3: Payment reminder automation';
COMMENT ON TABLE payments IS 'Payment transaction records';
COMMENT ON TABLE message_logs IS 'All communication logs for audit trail';
COMMENT ON TABLE automation_logs IS 'Workflow execution logs for monitoring';

-- ============================================
-- GRANT PERMISSIONS (Adjust based on your setup)
-- ============================================
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dental_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dental_app_user;

-- ============================================
-- Database is ready for n8n workflows
-- ============================================

SELECT 'Database schema created successfully!' as message;
SELECT COUNT(*) as clinics_count FROM clinics;
SELECT COUNT(*) as patients_count FROM patients;
SELECT COUNT(*) as appointments_count FROM appointments;
SELECT COUNT(*) as quotes_count FROM quotes;
SELECT COUNT(*) as payment_plans_count FROM payment_plans;