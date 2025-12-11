// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
    empleadoEmail: string
    empleadoNombre: string
    negocioNombre: string
    duenoNombre: string
}

Deno.serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        if (!RESEND_API_KEY) {
            throw new Error('RESEND_API_KEY not configured')
        }

        const { empleadoEmail, empleadoNombre, negocioNombre, duenoNombre }: EmailRequest = await req.json()

        // Validar datos requeridos
        if (!empleadoEmail) {
            throw new Error('empleadoEmail is required')
        }

        // Construir email HTML
        const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #2563EB, #7C3AED); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .header h1 { color: white; margin: 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .highlight { background: #e8f0fe; padding: 15px; border-radius: 8px; margin: 20px 0; }
    .button { display: inline-block; background: #2563EB; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎉 ¡Bienvenido a MarketMove!</h1>
    </div>
    <div class="content">
      <p>Hola${empleadoNombre ? ` <strong>${empleadoNombre}</strong>` : ''},</p>
      
      <p>Has sido añadido como empleado en <strong>${negocioNombre || 'el negocio'}</strong> por ${duenoNombre || 'el administrador'}.</p>
      
      <div class="highlight">
        <p><strong>📧 Tu email de acceso:</strong> ${empleadoEmail}</p>
        <p><strong>🔑 Contraseña:</strong> La que te proporcionó tu administrador</p>
      </div>
      
      <p>Con MarketMove CRM podrás:</p>
      <ul>
        <li>✅ Gestionar clientes y seguimiento</li>
        <li>✅ Ver el pipeline de ventas</li>
        <li>✅ Registrar actividades</li>
      </ul>
      
      <p style="text-align: center;">
        <a href="https://marketmove.app" class="button">Acceder a MarketMove</a>
      </p>
      
      <div class="footer">
        <p>Este es un mensaje automático de MarketMove CRM.</p>
        <p>Si no esperabas este email, puedes ignorarlo.</p>
      </div>
    </div>
  </div>
</body>
</html>
    `

        // Enviar email con Resend
        const res = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${RESEND_API_KEY}`,
            },
            body: JSON.stringify({
                from: 'MarketMove <noreply@marketmove.app>',
                to: [empleadoEmail],
                subject: `¡Bienvenido a ${negocioNombre || 'MarketMove'}!`,
                html: htmlContent,
            }),
        })

        const data = await res.json()

        if (!res.ok) {
            console.error('Resend error:', data)
            throw new Error(data.message || 'Error sending email')
        }

        return new Response(
            JSON.stringify({ success: true, messageId: data.id }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200
            }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 400
            }
        )
    }
})
