-- ============================================================
-- Courtify: RLS Policies, Trigger, and Mock Data
-- Schema already has: users, courts, court_slots, bookings, payments
-- ============================================================

-- ============================================================
-- 1. FUNCTIONS (must be before RLS policies)
-- ============================================================

-- Trigger function: auto-create public.users when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, phone, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
    )
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
            phone = COALESCE(EXCLUDED.phone, public.users.phone),
            role = COALESCE(EXCLUDED.role, public.users.role);
    RETURN NEW;
END;
$$;

-- Helper: check if current user is owner role
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() AND u.role = 'owner'
)
$$;

-- ============================================================
-- 2. ENABLE RLS (idempotent)
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.court_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 3. RLS POLICIES
-- ============================================================

-- users table: own profile management
DROP POLICY IF EXISTS "users_manage_own_profile" ON public.users;
CREATE POLICY "users_manage_own_profile"
ON public.users
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "owner_view_all_users" ON public.users;
CREATE POLICY "owner_view_all_users"
ON public.users
FOR SELECT
TO authenticated
USING (public.is_owner() OR id = auth.uid());

-- courts table: public read, owner write
DROP POLICY IF EXISTS "courts_public_read" ON public.courts;
CREATE POLICY "courts_public_read"
ON public.courts
FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "owner_manage_courts" ON public.courts;
CREATE POLICY "owner_manage_courts"
ON public.courts
FOR ALL
TO authenticated
USING (public.is_owner())
WITH CHECK (public.is_owner());

-- court_slots table: public read, owner write
DROP POLICY IF EXISTS "court_slots_public_read" ON public.court_slots;
CREATE POLICY "court_slots_public_read"
ON public.court_slots
FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "owner_manage_court_slots" ON public.court_slots;
CREATE POLICY "owner_manage_court_slots"
ON public.court_slots
FOR ALL
TO authenticated
USING (public.is_owner())
WITH CHECK (public.is_owner());

DROP POLICY IF EXISTS "system_update_slot_status" ON public.court_slots;
CREATE POLICY "system_update_slot_status"
ON public.court_slots
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- bookings table: users manage own bookings, owner sees all
DROP POLICY IF EXISTS "users_manage_own_bookings" ON public.bookings;
CREATE POLICY "users_manage_own_bookings"
ON public.bookings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "owner_view_all_bookings" ON public.bookings;
CREATE POLICY "owner_view_all_bookings"
ON public.bookings
FOR SELECT
TO authenticated
USING (public.is_owner() OR user_id = auth.uid());

DROP POLICY IF EXISTS "owner_update_bookings" ON public.bookings;
CREATE POLICY "owner_update_bookings"
ON public.bookings
FOR UPDATE
TO authenticated
USING (public.is_owner() OR user_id = auth.uid())
WITH CHECK (public.is_owner() OR user_id = auth.uid());

-- payments table: users see own payments, owner sees all
DROP POLICY IF EXISTS "users_view_own_payments" ON public.payments;
CREATE POLICY "users_view_own_payments"
ON public.payments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE b.id = booking_id AND b.user_id = auth.uid()
    )
    OR public.is_owner()
);

DROP POLICY IF EXISTS "users_insert_own_payments" ON public.payments;
CREATE POLICY "users_insert_own_payments"
ON public.payments
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE b.id = booking_id AND b.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "owner_manage_payments" ON public.payments;
CREATE POLICY "owner_manage_payments"
ON public.payments
FOR ALL
TO authenticated
USING (public.is_owner())
WITH CHECK (public.is_owner());

-- ============================================================
-- 4. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_court_slots_court_date ON public.court_slots(court_id, slot_date);
CREATE INDEX IF NOT EXISTS idx_court_slots_status ON public.court_slots(status);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_slot_id ON public.bookings(slot_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);

-- ============================================================
-- 5. TRIGGERS
-- ============================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 6. MOCK DATA (Demo users for testing)
-- ============================================================
DO $$
DECLARE
    customer_uuid UUID := gen_random_uuid();
    owner_uuid UUID := gen_random_uuid();
BEGIN
    -- Create customer demo user
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (customer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'nguyenvannam@courtify.vn', crypt('Courtify@2026', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Nguyen Van Nam', 'role', 'customer', 'phone', '0912345678'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (owner_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'owner@courtify.vn', crypt('Owner@2026', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Court Owner', 'role', 'owner', 'phone', '0987654321'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion skipped: %', SQLERRM;
END $$;
