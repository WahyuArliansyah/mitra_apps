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
    const { data: user, error: userError } = await supabase
      .from('pengguna')
      .select('fcm_token')
      .eq('id', record.id_siswa) 
      .single()

    if (userError || !user?.fcm_token) {
      return new Response(JSON.stringify({ message: "No token found" }), { status: 200 })
    }

    // 3. Konfigurasi Google Auth (Menggunakan 3 Secret Terpisah yang Baru)
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY')?.replace(/\\n/g, '\n') 
    const projectId = Deno.env.get('FCM_PROJECT_ID')

    // Pengecekan ekstra agar kita tahu jika ada secret yang typo/belum masuk
    if (!clientEmail || !privateKey || !projectId) {
        throw new Error("Secret FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY, atau FCM_PROJECT_ID belum terbaca!")
    }

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
            notification: {
              title: record.judul || "Informasi Baru",
              body: record.pesan || "Ada pembaruan tugas/materi.",
            },
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
    console.log("SUKSES Kirim Firebase:", fcmResult)

    return new Response(JSON.stringify({ message: "Notifikasi Terkirim", result: fcmResult }), { 
      headers: { "Content-Type": "application/json" } 
    })

  } catch (error) {
    console.error("Error utama:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }
})