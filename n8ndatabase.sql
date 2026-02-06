-- ===========================================
-- SACCO Loan Management System
-- Complete PostgreSQL Database Schema
-- Production Ready | Multi-tenant | Auditable
-- ===========================================

-- ===========================================
-- 1. DROP TABLES (for clean setup)
-- ===========================================
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS loan_repayments CASCADE;
DROP TABLE IF EXISTS loan_schedule CASCADE;
DROP TABLE IF EXISTS risk_assessments CASCADE;
DROP TABLE IF EXISTS recovery_actions CASCADE;
DROP TABLE IF EXISTS loan_guarantors CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS members CASCADE;
DROP TABLE IF EXISTS sacco CASCADE;
DROP VIEW IF EXISTS guarantor_exposure;
DROP VIEW IF EXISTS portfolio_risk_summary;

-- ===========================================
-- 2. CORE TABLES
-- ===========================================

-- Multi-tenant root table
CREATE TABLE sacco (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Members table
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sacco_id UUID NOT NULL REFERENCES sacco(id) ON DELETE CASCADE,
    member_number VARCHAR(50) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    national_id VARCHAR(50),
    employer_name VARCHAR(255),
    monthly_income NUMERIC(15,2) DEFAULT 0,
    savings_balance NUMERIC(15,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'restricted')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sacco_id, member_number)
);

-- Loans main table
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sacco_id UUID NOT NULL REFERENCES sacco(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    loan_number VARCHAR(50) NOT NULL,
    principal_amount NUMERIC(15,2) NOT NULL CHECK (principal_amount > 0),
    interest_rate NUMERIC(5,2) NOT NULL,
    total_payable NUMERIC(15,2) NOT NULL,
    monthly_installment NUMERIC(15,2) NOT NULL,
    disbursement_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue', 'defaulted', 'legal_review', 'written_off')),
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sacco_id, loan_number)
);

-- Guarantors for loans
CREATE TABLE loan_guarantors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    guarantor_member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    guaranteed_amount NUMERIC(15,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'released')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loan installment schedule
CREATE TABLE loan_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL,
    due_date DATE NOT NULL,
    amount_due NUMERIC(15,2) NOT NULL,
    amount_paid NUMERIC(15,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'partial')),
    paid_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(loan_id, installment_number)
);

-- Loan repayments tracking
CREATE TABLE loan_repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES loan_schedule(id),
    payment_date DATE NOT NULL,
    amount_paid NUMERIC(15,2) NOT NULL CHECK (amount_paid > 0),
    payment_method VARCHAR(50) CHECK (payment_method IN ('cash', 'bank', 'mobile_money', 'salary_deduction')),
    reference_number VARCHAR(100),
    collected_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk assessments history
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    calculation_details JSONB,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assessed_by VARCHAR(255)
);

-- Recovery actions log
CREATE TABLE recovery_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('sms', 'whatsapp', 'email', 'phone_call', 'hr_notice', 'legal_notice')),
    recipient_type VARCHAR(50) NOT NULL CHECK (recipient_type IN ('borrower', 'guarantor', 'employer', 'credit_manager')),
    recipient_contact VARCHAR(255),
    message TEXT,
    status VARCHAR(50) DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'delivered', 'read')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log for compliance
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sacco_id UUID REFERENCES sacco(id),
    entity_type VARCHAR(50),
    entity_id UUID,
    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(255),
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===========================================
-- 3. INDEXES FOR PERFORMANCE
-- ===========================================

-- sacco indexes
CREATE INDEX idx_sacco_registration ON sacco(registration_number);

-- members indexes
CREATE INDEX idx_members_sacco ON members(sacco_id);
CREATE INDEX idx_members_phone ON members(phone);
CREATE INDEX idx_members_status ON members(status);

-- loans indexes
CREATE INDEX idx_loans_sacco ON loans(sacco_id);
CREATE INDEX idx_loans_member ON loans(member_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_loans_risk ON loans(risk_level);
CREATE INDEX idx_loans_dates ON loans(disbursement_date, maturity_date);

-- loan_schedule indexes
CREATE INDEX idx_schedule_loan ON loan_schedule(loan_id);
CREATE INDEX idx_schedule_status ON loan_schedule(status);
CREATE INDEX idx_schedule_due_date ON loan_schedule(due_date);
CREATE INDEX idx_schedule_overdue ON loan_schedule(status, due_date) WHERE status = 'overdue';

-- loan_repayments indexes
CREATE INDEX idx_repayments_loan ON loan_repayments(loan_id);
CREATE INDEX idx_repayments_date ON loan_repayments(payment_date);

-- risk_assessments indexes
CREATE INDEX idx_risk_loan ON risk_assessments(loan_id);
CREATE INDEX idx_risk_date ON risk_assessments(assessed_at);

-- recovery_actions indexes
CREATE INDEX idx_recovery_loan ON recovery_actions(loan_id);
CREATE INDEX idx_recovery_date ON recovery_actions(created_at);
CREATE INDEX idx_recovery_type ON recovery_actions(action_type);

-- audit_log indexes
CREATE INDEX idx_audit_sacco ON audit_log(sacco_id);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_date ON audit_log(created_at);

-- ===========================================
-- 4. VIEWS FOR REPORTING
-- ===========================================

-- Guarantor exposure view
CREATE VIEW guarantor_exposure AS
SELECT 
    m.sacco_id,
    m.id AS guarantor_id,
    m.full_name AS guarantor_name,
    m.member_number,
    m.phone,
    m.savings_balance,
    COUNT(DISTINCT lg.loan_id) AS active_guarantees,
    SUM(lg.guaranteed_amount) AS total_guaranteed_amount,
    CASE 
        WHEN m.savings_balance > 0 
        THEN ROUND((SUM(lg.guaranteed_amount) / m.savings_balance) * 100, 2)
        ELSE 100.00
    END AS exposure_percentage
FROM members m
LEFT JOIN loan_guarantors lg ON m.id = lg.guarantor_member_id AND lg.status = 'active'
LEFT JOIN loans l ON lg.loan_id = l.id AND l.status IN ('active', 'overdue')
WHERE m.status = 'active'
GROUP BY m.id, m.full_name, m.member_number, m.phone, m.savings_balance, m.sacco_id;

-- Portfolio risk summary view
CREATE VIEW portfolio_risk_summary AS
SELECT 
    l.sacco_id,
    COUNT(*) AS total_loans,
    SUM(l.principal_amount) AS total_principal,
    COUNT(CASE WHEN l.risk_level = 'high' THEN 1 END) AS high_risk_loans,
    COUNT(CASE WHEN l.risk_level = 'critical' THEN 1 END) AS critical_risk_loans,
    COUNT(CASE WHEN l.status = 'overdue' THEN 1 END) AS overdue_loans,
    COUNT(CASE WHEN l.status = 'defaulted' THEN 1 END) AS defaulted_loans,
    ROUND(AVG(l.risk_score), 2) AS average_risk_score
FROM loans l
WHERE l.status IN ('active', 'overdue')
GROUP BY l.sacco_id;

-- ===========================================
-- 5. FUNCTIONS AND TRIGGERS
-- ===========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_sacco_updated_at 
    BEFORE UPDATE ON sacco 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_members_updated_at 
    BEFORE UPDATE ON members 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loans_updated_at 
    BEFORE UPDATE ON loans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_guarantors_updated_at 
    BEFORE UPDATE ON loan_guarantors 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_schedule_updated_at 
    BEFORE UPDATE ON loan_schedule 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update loan status based on schedule
CREATE OR REPLACE FUNCTION update_loan_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If loan schedule becomes overdue, update loan status
    IF NEW.status = 'overdue' AND OLD.status != 'overdue' THEN
        UPDATE loans 
        SET status = 'overdue', updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.loan_id;
    END IF;
    
    -- If all installments are paid, mark loan as completed
    IF NOT EXISTS (
        SELECT 1 FROM loan_schedule 
        WHERE loan_id = NEW.loan_id AND status != 'paid'
    ) THEN
        UPDATE loans 
        SET status = 'completed', updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.loan_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_loan_status_trigger
    AFTER UPDATE ON loan_schedule
    FOR EACH ROW EXECUTE FUNCTION update_loan_status();

-- Function to calculate PAR (Portfolio at Risk)
CREATE OR REPLACE FUNCTION calculate_par(days_threshold INTEGER)
RETURNS TABLE (
    sacco_id UUID,
    par_amount NUMERIC,
    par_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.sacco_id,
        COALESCE(SUM(ls.amount_due - ls.amount_paid), 0) AS par_amount,
        CASE 
            WHEN SUM(l.principal_amount) > 0 
            THEN ROUND((COALESCE(SUM(ls.amount_due - ls.amount_paid), 0) / SUM(l.principal_amount)) * 100, 2)
            ELSE 0
        END AS par_percentage
    FROM loans l
    LEFT JOIN loan_schedule ls ON l.id = ls.loan_id 
        AND ls.due_date < CURRENT_DATE - (days_threshold || ' days')::INTERVAL
        AND ls.status IN ('overdue', 'pending')
    WHERE l.status IN ('active', 'overdue')
    GROUP BY l.sacco_id;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- 6. SAMPLE DATA (for testing)
-- ===========================================

-- Insert sample SACCOs
INSERT INTO sacco (id, name, registration_number, contact_email, contact_phone, address) 
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Kampala Teachers SACCO', 'KTS001', 'info@kampalateachers.co.ug', '+256712345678', 'Kampala Road, Kampala'),
    ('22222222-2222-2222-2222-222222222222', 'Wakiso Farmers SACCO', 'WFS001', 'admin@wakiso.co.ug', '+256723456789', 'Wakiso Town, Wakiso');

-- Insert sample members
INSERT INTO members (id, sacco_id, member_number, full_name, phone, email, national_id, employer_name, monthly_income, savings_balance, status)
VALUES
    -- SACCO 1 members
    ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'KT001', 'John Omondi', '+256712000001', 'john@example.com', 'CM123456', 'Kampala University', 2500000, 5000000, 'active'),
    ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'KT002', 'Sarah Nalwanga', '+256712000002', 'sarah@example.com', 'CM123457', 'City Hospital', 1800000, 3000000, 'active'),
    ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'KT003', 'Robert Mugisha', '+256712000003', 'robert@example.com', 'CM123458', 'Ministry of Education', 3200000, 8000000, 'active'),
    -- SACCO 2 members
    ('66666666-6666-6666-6666-666666666666', '22222222-2222-2222-2222-222222222222', 'WF001', 'Grace Nakato', '+256723000001', 'grace@example.com', 'CM123459', 'Wakiso District', 1500000, 2000000, 'active'),
    ('77777777-7777-7777-7777-777777777777', '22222222-2222-2222-2222-222222222222', 'WF002', 'David Kato', '+256723000002', 'david@example.com', 'CM123460', 'Self Employed', 800000, 1000000, 'active');

-- Insert sample loans
INSERT INTO loans (id, sacco_id, member_id, loan_number, principal_amount, interest_rate, total_payable, monthly_installment, disbursement_date, maturity_date, status, risk_score, risk_level)
VALUES
    ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'KT-L001', 5000000, 12.5, 5625000, 468750, '2024-01-15', '2025-01-15', 'active', 35, 'medium'),
    ('99999999-9999-9999-9999-999999999999', '11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'KT-L002', 3000000, 15.0, 3450000, 287500, '2024-02-01', '2025-02-01', 'active', 25, 'low'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '66666666-6666-6666-6666-666666666666', 'WF-L001', 2000000, 18.0, 2360000, 196667, '2024-01-20', '2025-01-20', 'overdue', 65, 'high');

-- Insert sample guarantors
INSERT INTO loan_guarantors (id, loan_id, guarantor_member_id, guaranteed_amount, status)
VALUES
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555', 2500000, 'active'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '77777777-7777-7777-7777-777777777777', 1000000, 'active');

-- Insert sample loan schedule
INSERT INTO loan_schedule (id, loan_id, installment_number, due_date, amount_due, amount_paid, status)
VALUES
    -- Loan 1 installments
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', '88888888-8888-8888-8888-888888888888', 1, '2024-02-15', 468750, 468750, 'paid'),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '88888888-8888-8888-8888-888888888888', 2, '2024-03-15', 468750, 468750, 'paid'),
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', '88888888-8888-8888-8888-888888888888', 3, '2024-04-15', 468750, 0, 'pending'),
    -- Loan 2 installments
    ('gggggggg-gggg-gggg-gggg-gggggggggggg', '99999999-9999-9999-9999-999999999999', 1, '2024-03-01', 287500, 287500, 'paid'),
    ('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', '99999999-9999-9999-9999-999999999999', 2, '2024-04-01', 287500, 0, 'pending'),
    -- Loan 3 (overdue) installments
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, '2024-02-20', 196667, 0, 'overdue'),
    ('jjjjjjjj-jjjj-jjjj-jjjj-jjjjjjjjjjjj', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, '2024-03-20', 196667, 0, 'overdue');

-- Insert sample repayments
INSERT INTO loan_repayments (id, loan_id, schedule_id, payment_date, amount_paid, payment_method, reference_number, collected_by)
VALUES
    ('kkkkkkkk-kkkk-kkkk-kkkk-kkkkkkkkkkkk', '88888888-8888-8888-8888-888888888888', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '2024-02-14', 468750, 'bank', 'BNK202402141', 'John Doe'),
    ('llllllll-llll-llll-llll-llllllllllll', '88888888-8888-8888-8888-888888888888', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '2024-03-13', 468750, 'mobile_money', 'MM202403131', 'Jane Smith');

-- Insert sample risk assessments
INSERT INTO risk_assessments (id, loan_id, score, risk_level, calculation_details, assessed_at, assessed_by)
VALUES
    ('mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 65, 'high', 
     '{"loan_to_income": 25, "installment_ratio": 20, "days_overdue": 15, "guarantor_strength": 5}', 
     '2024-03-25 10:00:00', 'System');

-- Insert sample recovery actions
INSERT INTO recovery_actions (id, loan_id, action_type, recipient_type, recipient_contact, message, status)
VALUES
    ('nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'sms', 'borrower', '+256723000001', 'Dear Grace, your loan installment is overdue. Please make payment to avoid penalties.', 'sent');

-- ===========================================
-- 7. QUERY EXAMPLES
-- ===========================================

-- Query 1: Get all overdue loans with guarantor details
SELECT 
    l.loan_number,
    m.full_name AS borrower_name,
    m.phone AS borrower_phone,
    ls.due_date,
    ls.amount_due - ls.amount_paid AS overdue_amount,
    g.full_name AS guarantor_name,
    g.phone AS guarantor_phone
FROM loans l
JOIN members m ON l.member_id = m.id
JOIN loan_schedule ls ON l.id = ls.loan_id
LEFT JOIN loan_guarantors lg ON l.id = lg.loan_id
LEFT JOIN members g ON lg.guarantor_member_id = g.id
WHERE ls.status = 'overdue'
AND ls.due_date < CURRENT_DATE
ORDER BY ls.due_date;

-- Query 2: Get guarantor exposure report
SELECT 
    guarantor_name,
    member_number,
    savings_balance,
    total_guaranteed_amount,
    exposure_percentage,
    CASE 
        WHEN exposure_percentage > 70 THEN 'HIGH RISK'
        WHEN exposure_percentage > 50 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM guarantor_exposure
WHERE sacco_id = '11111111-1111-1111-1111-111111111111'
ORDER BY exposure_percentage DESC;

-- Query 3: Get portfolio at risk (PAR30)
SELECT * FROM calculate_par(30);

-- Query 4: Get recovery actions history
SELECT 
    l.loan_number,
    m.full_name AS borrower,
    ra.action_type,
    ra.recipient_type,
    ra.message,
    ra.status,
    ra.created_at
FROM recovery_actions ra
JOIN loans l ON ra.loan_id = l.id
JOIN members m ON l.member_id = m.id
ORDER BY ra.created_at DESC
LIMIT 10;

-- ===========================================
-- 8. COMMENTS AND DOCUMENTATION
-- ===========================================

COMMENT ON TABLE sacco IS 'Central SACCO registry table. Each SACCO is a tenant in the system.';
COMMENT ON TABLE members IS 'SACCO members with their financial and personal details.';
COMMENT ON TABLE loans IS 'Loan portfolio with risk scoring and status tracking.';
COMMENT ON TABLE loan_guarantors IS 'Guarantors for each loan to track exposure.';
COMMENT ON TABLE loan_schedule IS 'Installment schedule for each loan with payment status.';
COMMENT ON TABLE loan_repayments IS 'Detailed repayment history for audit trail.';
COMMENT ON TABLE risk_assessments IS 'Historical risk assessments for compliance and analysis.';
COMMENT ON TABLE recovery_actions IS 'All recovery communications sent to borrowers/guarantors.';
COMMENT ON TABLE audit_log IS 'Full audit trail for compliance and security.';

COMMENT ON VIEW guarantor_exposure IS 'View showing guarantor risk exposure percentages.';
COMMENT ON VIEW portfolio_risk_summary IS 'Aggregated portfolio risk metrics for reporting.';

-- ===========================================
-- DATABASE SETUP COMPLETE
-- ===========================================

-- Print success message
DO $$
BEGIN
    RAISE NOTICE '✅ SACCO Loan Management Database created successfully!';
    RAISE NOTICE '📊 Tables created: 9';
    RAISE NOTICE '📈 Views created: 2';
    RAISE NOTICE '🔧 Functions created: 3';
    RAISE NOTICE '📋 Sample data inserted for 2 SACCOs, 5 members, 3 loans';
END $$;
