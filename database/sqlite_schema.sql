-- ==========================================
-- SQLITE SCHEMA (LOCAL DB - OFFLINE FIRST)
-- ALIGNED WITH BR-G1 TO BR-O6
-- ==========================================

-- 1. USER SESSION
CREATE TABLE user_session (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE NOT NULL, -- UUID string
    email TEXT NOT NULL,
    full_name TEXT,
    role TEXT CHECK (role IN ('customer', 'owner', 'admin')),
    access_token TEXT,
    refresh_token TEXT,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- BR-G1: ONLY ONE VENUE. Local device just stores this single configuration.
CREATE TABLE cached_venue (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE NOT NULL,
    owner_id TEXT NOT NULL,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    price_per_hour REAL NOT NULL,
    opening_time TEXT DEFAULT '05:00:00',
    closing_time TEXT DEFAULT '23:00:00',
    last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. CACHED SUB_COURTS
CREATE TABLE cached_sub_courts (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE NOT NULL,
    venue_id TEXT NOT NULL,
    name TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. LOCAL TIME_SLOTS (Template configuration)
-- BR-C6, BR-O1: Stores slot states (available, locked)
CREATE TABLE local_time_slots (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE NOT NULL,
    sub_court_id TEXT NOT NULL,
    slot_date TEXT NOT NULL, -- YYYY-MM-DD
    start_time TEXT NOT NULL, -- HH:MM:SS
    end_time TEXT NOT NULL,
    status TEXT CHECK (status IN ('available', 'locked')) DEFAULT 'available',
    last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. LOCAL BOOKINGS (With Sync Status via BR-G5)
CREATE TABLE local_bookings (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE, 
    customer_id TEXT NOT NULL,
    sub_court_id TEXT NOT NULL,
    book_date TEXT NOT NULL, -- "YYYY-MM-DD"
    start_time TEXT NOT NULL, -- "HH:MM:SS"
    end_time TEXT NOT NULL,
    
    -- BR-C9, BR-O4
    status TEXT CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')) DEFAULT 'pending',
    
    -- BR-C12
    payment_status TEXT CHECK (payment_status IN ('unpaid', 'paid')) DEFAULT 'unpaid',

    total_price REAL NOT NULL,
    
    -- BR-O6 (Check-in flag for completion logic)
    has_checked_in INTEGER DEFAULT 0, -- 0/1 boolean

    synced INTEGER DEFAULT 0, -- 0 = Not Synced, 1 = Synced, 2 = Conflict (BR-G5)
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- NOTE: G5 rule ensures UI calls this SQLite repo exclusively, and a separate service layer polls
-- the differences (where `synced = 0`) up to Supabase.
