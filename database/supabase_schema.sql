-- ==========================================
-- SUPABASE POSTGRESQL SCHEMA (REMOTE DB)
-- ALIGNED WITH GLOBAL RULES (BR-G1 TO BR-O6)
-- ==========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL, -- BR-C2: One email = one account
    full_name VARCHAR(150),
    role VARCHAR(50) CHECK (role IN ('customer', 'owner', 'admin')) DEFAULT 'customer',
    phone_number VARCHAR(20),
    avatar_url TEXT,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BR-G1: ONLY ONE VENUE IS MANAGED.
-- We still keep a 'venues' or 'courts' table conceptually to hold the global settings for that 1 venue, 
-- but in logic it will only ever have 1 row (or owner manages their instance). Let's call it `venue`.
CREATE TABLE venue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    images TEXT[], 
    price_per_hour DECIMAL(10, 2) NOT NULL,
    rules TEXT,
    -- BR-G6: Venue opens at 05:00 and closes at 23:00
    opening_time TIME DEFAULT '05:00:00',
    closing_time TIME DEFAULT '23:00:00',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. SUB_COURTS (The individual courts inside the 1 venue)
CREATE TABLE sub_courts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venue_id UUID REFERENCES venue(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- e.g., "Court 1", "Court 2"
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TIME_SLOTS (Template for owner openings)
-- BR-G2: Fixed slots (1h or 2h). We store the exact slot definitions here for the owner to manage.
-- BR-O1: Owner can open/lock slots.
CREATE TABLE time_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sub_court_id UUID REFERENCES sub_courts(id) ON DELETE CASCADE,
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    -- BR-O1, BR-O2: 'available', 'locked'
    status VARCHAR(50) CHECK (status IN ('available', 'locked')) DEFAULT 'available',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Ensure exactly 1h or 2h slot size constraint roughly at insert if needed, or handle in app logic.
    UNIQUE (sub_court_id, slot_date, start_time)
);

-- 5. BOOKINGS
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    sub_court_id UUID REFERENCES sub_courts(id) ON DELETE RESTRICT,
    book_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- BR-C9, BR-O4: pending, confirmed, completed, cancelled
    status VARCHAR(50) CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')) DEFAULT 'pending',
    
    -- BR-C12: UNPAID, PAID
    payment_status VARCHAR(50) CHECK (payment_status IN ('unpaid', 'paid')) DEFAULT 'unpaid',
    
    total_price DECIMAL(10, 2) NOT NULL,
    
    -- BR-O6: Customer has checked in
    has_checked_in BOOLEAN DEFAULT FALSE,

    synced SMALLINT DEFAULT 1, -- For offline-sync tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- BR-C8, BR-G3: Prevent double booking on same sub_court, date and time
    EXCLUDE USING gist (
        sub_court_id WITH =,
        book_date WITH =,
        tsrange(
            (book_date + start_time)::timestamp,
            (book_date + end_time)::timestamp
        ) WITH &&
    ) WHERE (status != 'cancelled') -- Cancelled bookings don't overlap
);

-- 6. PAYMENTS
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    method VARCHAR(50) CHECK (method IN ('cash', 'online', 'vnpay', 'momo')) NOT NULL,
    status VARCHAR(50) CHECK (status IN ('pending', 'success', 'failed')) DEFAULT 'pending',
    transaction_ref VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security)

-- BR-C3: Customers can only see and cancel their own bookings.
-- BR-O3: Owner sees all bookings.
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers view own bookings"
ON bookings FOR SELECT
USING (auth.uid() = customer_id);

CREATE POLICY "Customers update own bookings (to cancel)"
ON bookings FOR UPDATE
USING (auth.uid() = customer_id);

CREATE POLICY "Owners view all bookings"
ON bookings FOR SELECT
USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'owner'
));

CREATE POLICY "Owners update all bookings"
ON bookings FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'owner'
));
