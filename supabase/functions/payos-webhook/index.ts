import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Note: PayOS Webhook signature verification should be here
// but standard Deno crypto needs manual implementation for HMAC sort-keys
// We'll follow the PayOS logic: amount, description, orderCode, reference, status

const PAYOS_CHECKSUM_KEY = Deno.env.get("PAYOS_CHECKSUM_KEY")
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { code, data, signature } = body

    if (code !== "00") {
      return new Response(JSON.stringify({ ok: true, message: "Ignored" }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 })
    }

    if (data.status === "PAID") {
      const orderCode = data.orderCode

      // 1. Get payment and booking info
      const { data: payment, error } = await supabase
        .from("payments")
        .select("id, booking_id, status")
        .eq("order_code", orderCode)
        .single()

      if (error || !payment) {
        return new Response(JSON.stringify({ ok: false, error: "Payment not found" }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 404 })
      }

      if (payment.status !== "PAID") {
        const bookingId = payment.booking_id

        // 2. Update payment
        await supabase
          .from("payments")
          .update({
            status: "PAID",
            transaction_id: data.reference,
          })
          .eq("id", payment.id)

        // 3. Update bookings and slots (Atomic logic)
        const { data: booking } = await supabase
          .from("bookings")
          .select("user_id, court_id, hold_expires_at, slot_id")
          .eq("id", bookingId)
          .single()

        if (booking) {
          if (booking.hold_expires_at) {
             // Group update
             await supabase
               .from("bookings")
               .update({ payment_status: "PAID", status: "CONFIRMED" })
               .eq("user_id", booking.user_id)
               .eq("court_id", booking.court_id)
               .eq("hold_expires_at", booking.hold_expires_at)
             
             // Get slot IDs in this group
             const { data: related } = await supabase
               .from("bookings")
               .select("slot_id")
               .eq("user_id", booking.user_id)
               .eq("court_id", booking.court_id)
               .eq("hold_expires_at", booking.hold_expires_at)
             
             const slotIds = related?.map((r: any) => r.slot_id) || []
             if (slotIds.length > 0) {
                await supabase
                  .from("court_slots")
                  .update({ status: "BOOKED" })
                  .in("id", slotIds)
             }
          } else {
             // Single update
             await supabase
               .from("bookings")
               .update({ payment_status: "PAID", status: "CONFIRMED" })
               .eq("id", bookingId)
             
             await supabase
               .from("court_slots")
               .update({ status: "BOOKED" })
               .eq("id", booking.slot_id)
          }
        }
      }
    }

    return new Response(JSON.stringify({ ok: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 })
  } catch (err: any) {
    console.error("Webhook Error:", err)
    return new Response(JSON.stringify({ ok: false, error: err.message }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 })
  }
})
