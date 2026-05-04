import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://esm.sh/google-auth-library@8.7.0'

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record

    // 1. Inisialisasi Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Ambil token FCM siswa dari tabel pengguna
    // Pastikan kolom 'id' di tabel pengguna cocok dengan 'id_siswa' di tabel notifikasi
    const { data: user, error: userError } = await supabase
      .from('pengguna')
      .select('fcm_token')
      .eq('id', record.id_siswa) 
      .single()

    if (userError || !user?.fcm_token) {
      console.log("User tidak ditemukan atau token kosong")
      return new Response(JSON.stringify({ message: "No token found" }), { status: 200 })
    }

    // 3. Konfigurasi Google Auth untuk Firebase
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY')?.replace(/\\n/g, '\n')
    const projectId = Deno.env.get('FCM_PROJECT_ID')

    const jwtClient = new JWT(
      clientEmail,
      null,
      privateKey,
      ['https://www.googleapis.com/auth/cloud-platform']
    )

    const tokenResponse = await jwtClient.authorize()
    const accessToken = tokenResponse.access_token

    // 4. Kirim Notifikasi ke Firebase V1 API
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: user.fcm_token,
            // Struktur ini yang membuat notifikasi muncul di layar luar (pop-up)
            notification: {
              title: record.judul || "Notifikasi Baru",
              body: record.pesan || "Ada informasi baru untuk Anda",
            },
            // Tambahan agar Android memberikan prioritas tinggi (seperti WA)
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channel_id: "high_importance_channel" 
              }
            },
            data: {
              id_notif: record.id.toString(),
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        }),
      }
    )

    const fcmResult = await fcmResponse.json()
    console.log("Hasil kirim Firebase:", fcmResult)

    return new Response(JSON.stringify({ message: "Notifikasi Terkirim", result: fcmResult }), { 
      headers: { "Content-Type": "application/json" } 
    })

  } catch (error) {
    console.error("Error utama:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }
})