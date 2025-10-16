-- ============================================
-- CPF Portal - Supabase Database Schema
-- ============================================
-- Run this script in Supabase SQL Editor
-- to set up all tables and security policies
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ADMINS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'admin',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_admins_user_id ON admins(user_id);
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);

-- ============================================
-- 2. NGO PROPOSALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS ngo_proposals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ngo_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    date_of_registration TEXT,
    country TEXT,
    state TEXT,
    district TEXT,
    registered_address TEXT,
    corresponding_address TEXT,
    
    -- Chief Functionary Details
    chief_functionary_name TEXT,
    chief_functionary_email TEXT,
    chief_functionary_phone TEXT,
    
    -- Financial Information
    financial_year TEXT,
    gross_amount_raised NUMERIC,
    pan TEXT,
    tan TEXT,
    fcra_registration TEXT,
    csr_registration TEXT,
    darpan_id TEXT,
    gst_registration TEXT,
    
    -- Work Areas
    sector_of_work TEXT[], -- Array of sectors
    other_sectors TEXT,
    networks TEXT,
    
    -- Status and Verification
    status TEXT DEFAULT 'pending', -- pending, under_review, approved, rejected, verified
    verification_status TEXT DEFAULT 'pending',
    profile_complete BOOLEAN DEFAULT false,
    
    -- Certificates
    due_diligence_certificate_enabled BOOLEAN DEFAULT false,
    due_diligence_certificate_enabled_data JSONB,
    compliance_certificate_enabled BOOLEAN DEFAULT false,
    compliance_certificate_enabled_data JSONB,
    letterhead_certificate_enabled BOOLEAN DEFAULT false,
    letterhead_certificate_enabled_data JSONB,
    
    -- Logo and Documents
    logo JSONB,
    
    -- Admin Review
    admin_comments TEXT,
    reviewed_by TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for NGO proposals
CREATE INDEX IF NOT EXISTS idx_ngo_proposals_user_id ON ngo_proposals(user_id);
CREATE INDEX IF NOT EXISTS idx_ngo_proposals_email ON ngo_proposals(email);
CREATE INDEX IF NOT EXISTS idx_ngo_proposals_status ON ngo_proposals(status);

-- ============================================
-- 3. YEARLY DATA TABLE (NGO Submissions)
-- ============================================
-- Financial Years are now generic: "F.Y. 1", "F.Y. 2", "F.Y. 3"
-- Documents field structure supports multiple files per document type:
-- {
--   "audit_report": [
--     {"filename": "...", "download_url": "...", "file_path": "...", "file_size": 1024, "original_name": "...", "uploaded_at": "..."},
--     {"filename": "...", "download_url": "...", ...}
--   ],
--   "activity_report": [...],
--   "itr_acknowledgment": [...],
--   "utilization_certificate": [...],
--   "annual_return": [...],  -- NEW: Annual Return Proof (multiple files)
--   "tan_form_24q": [...],   -- NEW: TAN Form 24Q (multiple files)
--   "tan_form_26q": [...],   -- NEW: TAN Form 26Q (multiple files)
--   "tan_tds_related": [...]  -- NEW: TDS-Related Documents (multiple files)
-- }
CREATE TABLE IF NOT EXISTS yearly_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ngo_id UUID REFERENCES ngo_proposals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    financial_year TEXT NOT NULL, -- F.Y. 1, F.Y. 2, F.Y. 3
    documents JSONB NOT NULL, -- Store all document metadata (supports multiple files per type)
    document_category_count INTEGER DEFAULT 0, -- Number of document categories
    total_file_count INTEGER DEFAULT 0, -- Total number of files uploaded
    status TEXT DEFAULT 'submitted',
    storage_type TEXT DEFAULT 'supabase',
    
    submitted_by TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for yearly data
CREATE INDEX IF NOT EXISTS idx_yearly_data_ngo_id ON yearly_data(ngo_id);
CREATE INDEX IF NOT EXISTS idx_yearly_data_user_id ON yearly_data(user_id);
CREATE INDEX IF NOT EXISTS idx_yearly_data_financial_year ON yearly_data(financial_year);

-- ============================================
-- 4. PROPOSALS TABLE (NGO Funding Proposals)
-- ============================================
CREATE TABLE IF NOT EXISTS proposals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ngo_id UUID REFERENCES ngo_proposals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ngo_name TEXT NOT NULL,
    
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    requested_amount NUMERIC NOT NULL,
    
    status TEXT DEFAULT 'submitted', -- submitted, under_review, approved, rejected
    
    document JSONB, -- Store document metadata
    has_document BOOLEAN DEFAULT false,
    storage_type TEXT DEFAULT 'supabase',
    
    sent_to_cpf BOOLEAN DEFAULT false,
    
    submitted_by TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for proposals
CREATE INDEX IF NOT EXISTS idx_proposals_ngo_id ON proposals(ngo_id);
CREATE INDEX IF NOT EXISTS idx_proposals_user_id ON proposals(user_id);
CREATE INDEX IF NOT EXISTS idx_proposals_status ON proposals(status);

-- ============================================
-- 5. DONOR PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS donor_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    organization TEXT,
    
    donor_type TEXT, -- individual, corporate, foundation
    interests TEXT[], -- Array of interest areas
    
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    
    admin_comments TEXT,
    reviewed_by TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for donor profiles
CREATE INDEX IF NOT EXISTS idx_donor_profiles_user_id ON donor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_donor_profiles_email ON donor_profiles(email);
CREATE INDEX IF NOT EXISTS idx_donor_profiles_status ON donor_profiles(status);

-- ============================================
-- 6. DONORS TABLE (Legacy - for compatibility)
-- ============================================
CREATE TABLE IF NOT EXISTS donors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    organization TEXT,
    
    status TEXT DEFAULT 'pending',
    
    admin_comments TEXT,
    reviewed_by TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for donors
CREATE INDEX IF NOT EXISTS idx_donors_user_id ON donors(user_id);
CREATE INDEX IF NOT EXISTS idx_donors_email ON donors(email);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE ngo_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE yearly_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE donor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE donors ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if user is an admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins
        WHERE user_id = user_uuid
        AND role = 'admin'
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ADMINS TABLE POLICIES
-- ============================================

-- Admins can read their own record
CREATE POLICY "Admins can read own record"
    ON admins FOR SELECT
    USING (auth.uid() = user_id);

-- Allow creating admin account (first admin)
CREATE POLICY "Allow admin creation"
    ON admins FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admins can update their own record or other admins if they are admin
CREATE POLICY "Admins can update records"
    ON admins FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Only admins can delete admin records
CREATE POLICY "Admins can delete records"
    ON admins FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- NGO PROPOSALS POLICIES
-- ============================================

-- NGOs can read their own proposals, admins can read all
CREATE POLICY "NGOs read own proposals"
    ON ngo_proposals FOR SELECT
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Authenticated users can create proposals
CREATE POLICY "Users can create proposals"
    ON ngo_proposals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- NGOs can update their own proposals, admins can update all
CREATE POLICY "NGOs update own proposals"
    ON ngo_proposals FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Only admins can delete proposals
CREATE POLICY "Admins delete proposals"
    ON ngo_proposals FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- YEARLY DATA POLICIES
-- ============================================

-- NGOs can read their own data, admins can read all
CREATE POLICY "NGOs read own yearly data"
    ON yearly_data FOR SELECT
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- NGOs can create their own yearly data
CREATE POLICY "NGOs create yearly data"
    ON yearly_data FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- NGOs can update their own data, admins can update all
CREATE POLICY "NGOs update own yearly data"
    ON yearly_data FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Admins can delete yearly data
CREATE POLICY "Admins delete yearly data"
    ON yearly_data FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- PROPOSALS POLICIES
-- ============================================

-- NGOs can read their own proposals, admins can read all
CREATE POLICY "NGOs read own proposals submissions"
    ON proposals FOR SELECT
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- NGOs can create proposals
CREATE POLICY "NGOs create proposals"
    ON proposals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- NGOs can update their own proposals, admins can update all
CREATE POLICY "NGOs update own proposals submissions"
    ON proposals FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Admins can delete proposals
CREATE POLICY "Admins delete proposals submissions"
    ON proposals FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- DONOR PROFILES POLICIES
-- ============================================

-- Donors can read their own profile, admins can read all
CREATE POLICY "Donors read own profile"
    ON donor_profiles FOR SELECT
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Authenticated users can create donor profiles
CREATE POLICY "Users create donor profile"
    ON donor_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Donors can update their own profile, admins can update all
CREATE POLICY "Donors update own profile"
    ON donor_profiles FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Admins can delete donor profiles
CREATE POLICY "Admins delete donor profiles"
    ON donor_profiles FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- DONORS POLICIES (Legacy)
-- ============================================

-- Donors can read their own record, admins can read all
CREATE POLICY "Donors read own record"
    ON donors FOR SELECT
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Authenticated users can create donor records
CREATE POLICY "Users create donor record"
    ON donors FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Donors can update their own record, admins can update all
CREATE POLICY "Donors update own record"
    ON donors FOR UPDATE
    USING (auth.uid() = user_id OR is_admin(auth.uid()));

-- Admins can delete donor records
CREATE POLICY "Admins delete donor records"
    ON donors FOR DELETE
    USING (is_admin(auth.uid()));

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for all tables
CREATE TRIGGER update_admins_updated_at
    BEFORE UPDATE ON admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ngo_proposals_updated_at
    BEFORE UPDATE ON ngo_proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_yearly_data_updated_at
    BEFORE UPDATE ON yearly_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_proposals_updated_at
    BEFORE UPDATE ON proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donor_profiles_updated_at
    BEFORE UPDATE ON donor_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donors_updated_at
    BEFORE UPDATE ON donors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- INDEXES FOR BETTER PERFORMANCE
-- ============================================

-- Additional composite indexes
CREATE INDEX IF NOT EXISTS idx_ngo_proposals_user_status ON ngo_proposals(user_id, status);
CREATE INDEX IF NOT EXISTS idx_proposals_ngo_status ON proposals(ngo_id, status);
CREATE INDEX IF NOT EXISTS idx_yearly_data_ngo_year ON yearly_data(ngo_id, financial_year);

-- ============================================
-- VIEWS FOR ADMIN DASHBOARD
-- ============================================

-- View for NGO statistics
CREATE OR REPLACE VIEW ngo_statistics AS
SELECT
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE status = 'approved' OR status = 'verified') as approved_count,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected_count,
    COUNT(*) FILTER (WHERE status = 'under_review') as under_review_count,
    COUNT(*) as total_count
FROM ngo_proposals;

-- View for donor statistics
CREATE OR REPLACE VIEW donor_statistics AS
SELECT
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_count,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected_count,
    COUNT(*) as total_count
FROM (
    SELECT status FROM donor_profiles
    UNION ALL
    SELECT status FROM donors
) combined_donors;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- ============================================
-- COMPLETE!
-- ============================================
-- All tables, policies, triggers, and indexes created successfully
-- You can now use your Supabase database with the Flutter app
-- ============================================


