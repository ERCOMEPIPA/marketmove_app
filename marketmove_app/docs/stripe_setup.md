# 🔧 Configuración de Stripe + Supabase

## Paso 1: Ejecutar en Supabase SQL Editor

```sql
-- Añadir campos de Stripe y facturación a la tabla planes
ALTER TABLE planes 
  ADD COLUMN IF NOT EXISTS stripe_price_id TEXT,
  ADD COLUMN IF NOT EXISTS tipo_facturacion TEXT DEFAULT 'mensual';

-- Añadir campos de Stripe a la tabla perfiles
ALTER TABLE perfiles 
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;
```

---

## Paso 2: Crear Productos y Precios en Stripe Dashboard

1. Ve a https://dashboard.stripe.com/products
2. Clic en **"+ Add product"**
3. Crea un producto para cada plan:

| Plan | Nombre | Precio | Facturación |
|------|--------|--------|-------------|
| Básico | Plan Básico MarketMove | €0/mes | Mensual |
| Pro | Plan Pro MarketMove | €29/mes | Mensual |
| Enterprise | Plan Enterprise MarketMove | €99/mes | Mensual |

4. Después de crear cada producto, copia el **Price ID** (empieza con `price_`)
5. Ve a MarketMove como Superadmin → Gestión de Planes
6. Edita cada plan y pega el Price ID correspondiente

---

## Paso 3: Configurar Edge Functions en Supabase

Ve a **Supabase Dashboard** → **Edge Functions** y crea estas funciones:

### 3.1 Crear función `create-checkout`

```typescript
// supabase/functions/create-checkout/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  try {
    const { priceId, successUrl, cancelUrl } = await req.json()

    // Obtener usuario de Supabase
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('No user found')

    // Obtener o crear customer de Stripe
    const { data: profile } = await supabase
      .from('perfiles')
      .select('stripe_customer_id, email')
      .eq('id', user.id)
      .single()

    let customerId = profile?.stripe_customer_id

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_user_id: user.id }
      })
      customerId = customer.id
      
      await supabase
        .from('perfiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
    }

    // Crear sesión de checkout
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
    })

    return new Response(
      JSON.stringify({ url: session.url }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

### 3.2 Crear función `stripe-webhook`

```typescript
// supabase/functions/stripe-webhook/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')!
  const body = await req.text()

  try {
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        const customerId = session.customer as string
        const subscriptionId = session.subscription as string

        // Obtener el plan desde el precio
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const priceId = subscription.items.data[0].price.id

        // Buscar el plan con ese price_id
        const { data: plan } = await supabase
          .from('planes')
          .select('id')
          .eq('stripe_price_id', priceId)
          .single()

        // Actualizar perfil del usuario
        await supabase
          .from('perfiles')
          .update({
            stripe_subscription_id: subscriptionId,
            suscripcion_estado: 'activa',
            plan_id: plan?.id
          })
          .eq('stripe_customer_id', customerId)

        break
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription
        const customerId = subscription.customer as string

        await supabase
          .from('perfiles')
          .update({
            suscripcion_estado: 'cancelada',
            stripe_subscription_id: null
          })
          .eq('stripe_customer_id', customerId)

        break
      }
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 })
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }
})
```

### 3.3 Crear función `create-portal`

```typescript
// supabase/functions/create-portal/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  try {
    const { returnUrl } = await req.json()

    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('No user found')

    const { data: profile } = await supabase
      .from('perfiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()

    if (!profile?.stripe_customer_id) {
      throw new Error('No Stripe customer found')
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: profile.stripe_customer_id,
      return_url: returnUrl,
    })

    return new Response(
      JSON.stringify({ url: session.url }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

---

## Paso 4: Configurar Variables de Entorno en Supabase

Ve a **Supabase Dashboard** → **Edge Functions** → **Secrets** y añade:

| Nombre | Valor |
|--------|-------|
| `STRIPE_SECRET_KEY` | `sk_test_...` (de Stripe Dashboard) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` (del webhook en Stripe) |

---

## Paso 5: Configurar Webhook en Stripe

1. Ve a https://dashboard.stripe.com/webhooks
2. Clic en **"Add endpoint"**
3. URL: `https://[TU-PROYECTO].supabase.co/functions/v1/stripe-webhook`
4. Eventos a escuchar:
   - `checkout.session.completed`
   - `customer.subscription.deleted`
   - `customer.subscription.updated`
5. Copia el **Signing secret** y añádelo como `STRIPE_WEBHOOK_SECRET`

---

## ✅ ¡Listo!

Ahora los dueños pueden suscribirse a planes usando Stripe Checkout.
