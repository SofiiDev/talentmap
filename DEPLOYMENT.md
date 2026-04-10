# 🚀 TalentMap — Guía de Deployment Completo

## Arquitectura
```
GitHub (código) → Netlify (hosting/deploy automático)
                       ↓
               Supabase (base de datos + auth)
                       ↓
               Google OAuth (login con Google)
```

---

## PASO 1 — Supabase (Base de Datos)

### 1.1 Crear cuenta y proyecto

1. Ir a **https://supabase.com** → Sign Up (gratis)
2. Crear nuevo proyecto:
   - **Name:** `talentmap`
   - **Database Password:** [guarda esto, lo necesitarás]
   - **Region:** South America (São Paulo) o la más cercana
3. Esperar ~2 minutos a que el proyecto esté listo

### 1.2 Ejecutar el schema

1. En Supabase → **SQL Editor** → **New query**
2. Copiar **todo** el contenido de `supabase/migrations/001_initial_schema.sql`
3. Click **Run** (Ctrl+Enter)
4. Verificar que dice "Success" sin errores

### 1.3 Obtener las credenciales

1. Ir a **Settings** → **API**
2. Copiar:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon public key** → `VITE_SUPABASE_ANON_KEY`
3. Guardar en tu `.env`:

```env
VITE_SUPABASE_URL=https://xxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
VITE_ANTHROPIC_API_KEY=sk-ant-...
```

---

## PASO 2 — Google OAuth (Login con Google)

### 2.1 Google Cloud Console

1. Ir a **https://console.cloud.google.com**
2. Crear nuevo proyecto → nombre: `TalentMap`
3. Ir a **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. **Application type:** Web application
6. **Name:** TalentMap Web
7. **Authorized redirect URIs** → agregar:
   ```
   https://[TU-PROJECT-ID].supabase.co/auth/v1/callback
   ```
   (Reemplaza `[TU-PROJECT-ID]` con el ID de tu proyecto Supabase)
8. Click **Create** → copiar **Client ID** y **Client Secret**

### 2.2 Configurar en Supabase

1. En Supabase → **Authentication** → **Providers** → **Google**
2. **Enable Google provider** = ON
3. Pegar el **Client ID** y **Client Secret** de Google
4. Click **Save**

### 2.3 Configurar URLs permitidas en Supabase

1. Supabase → **Authentication** → **URL Configuration**
2. **Site URL:** `https://tu-app.netlify.app`
3. **Redirect URLs:** agregar:
   ```
   https://tu-app.netlify.app
   https://tu-app.netlify.app/
   http://localhost:3000
   http://localhost:5173
   ```

---

## PASO 3 — GitHub (Control de versiones)

### 3.1 Crear repositorio

```bash
# En tu computadora, dentro de la carpeta talentmap/
git init
git add .
git commit -m "feat: TalentMap initial commit"
```

Luego en **https://github.com/new**:
- **Repository name:** `talentmap`
- **Visibility:** Private (recomendado)
- Click **Create repository**

```bash
git remote add origin https://github.com/TU-USUARIO/talentmap.git
git branch -M main
git push -u origin main
```

### 3.2 Archivo .env.local para desarrollo local

Crear `.env.local` (NO commitear):
```env
VITE_SUPABASE_URL=https://xxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
VITE_ANTHROPIC_API_KEY=sk-ant-api03-...
```

---

## PASO 4 — Netlify (Deploy)

### 4.1 Conectar con GitHub

1. Ir a **https://app.netlify.com** → Sign up/Log in
2. **Add new site** → **Import an existing project** → **Deploy with GitHub**
3. Autorizar Netlify en GitHub
4. Seleccionar el repositorio `talentmap`
5. Configuración de build:
   - **Branch to deploy:** `main`
   - **Build command:** `npm run build`
   - **Publish directory:** `dist`
6. Click **Deploy site**

### 4.2 Variables de entorno en Netlify

1. En Netlify → tu site → **Site configuration** → **Environment variables**
2. Click **Add a variable** para cada una:

| Key | Value |
|-----|-------|
| `VITE_SUPABASE_URL` | `https://xxxxxxxxxx.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIs...` |
| `ANTHROPIC_API_KEY` | `sk-ant-api03-...` (sin VITE_ para la Netlify Function) |
| `VITE_APP_URL` | `https://tu-app.netlify.app` |

> ⚠️ **Importante:** `ANTHROPIC_API_KEY` (sin VITE_) solo se usa en la Netlify Function y NUNCA se expone al frontend.

3. Click **Save** → **Trigger deploy** → **Deploy site**

### 4.3 Obtener tu URL de Netlify

Tu app estará en: `https://[nombre-random].netlify.app`

Puedes cambiar el nombre en: **Site configuration** → **Site details** → **Change site name**

---

## PASO 5 — Actualizar URLs de OAuth

### 5.1 Actualizar en Google Cloud Console

1. Ir a **APIs & Services** → **Credentials** → tu OAuth client
2. **Authorized redirect URIs** → agregar:
   ```
   https://tu-app.netlify.app
   ```

### 5.2 Actualizar en Supabase

1. Supabase → **Authentication** → **URL Configuration**
2. **Site URL:** `https://tu-app.netlify.app`
3. Agregar a **Redirect URLs:**
   ```
   https://tu-app.netlify.app
   https://tu-app.netlify.app/
   ```

---

## PASO 6 — Para la app estática (sin React/Vite)

Si prefieres usar el `public/index.html` directamente (sin build):

### 6.1 Agregar variables al HTML

En Netlify → **Site configuration** → **Post processing** → **Snippet injection**

O crear un archivo `netlify/edge-functions/inject-env.js`:
```javascript
export default async (request, context) => {
  const response = await context.next()
  const html = await response.text()
  const injected = html.replace(
    'window.__ENV_SUPABASE_URL__ || \'\'',
    `'${process.env.VITE_SUPABASE_URL}'`
  ).replace(
    'window.__ENV_SUPABASE_ANON__ || \'\'',
    `'${process.env.VITE_SUPABASE_ANON_KEY}'`
  )
  return new Response(injected, response)
}
```

### 6.2 O directamente hardcodear en producción (no recomendado para anon key)

El `anon key` de Supabase es seguro de exponer (está protegido por RLS), pero la API key de Anthropic debe ir SOLO en las Netlify Functions.

---

## PASO 7 — Workflow de desarrollo

```bash
# Desarrollo local
npm install
npm run dev
# → http://localhost:3000

# Commitear cambios → auto-deploy en Netlify
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main
# → Netlify detecta el push y hace deploy automático en ~2 min
```

---

## PASO 8 — Gmail API (opcional, para enviar encuestas)

### 8.1 Habilitar Gmail API en Google Cloud

1. Google Cloud Console → **APIs & Services** → **Library**
2. Buscar "Gmail API" → **Enable**
3. En tu OAuth Client → **Scopes** agregar:
   - `https://www.googleapis.com/auth/gmail.compose`
   - `https://www.googleapis.com/auth/gmail.send`

### 8.2 En Supabase Auth

1. Authentication → Providers → Google → Additional scopes:
   ```
   openid email profile https://www.googleapis.com/auth/gmail.compose
   ```

### 8.3 En la app

Cuando el usuario hace login con Google, el token de acceso queda en la sesión de Supabase:
```javascript
const { data: { session } } = await supabase.auth.getSession()
const googleToken = session.provider_token // Token de Google
// Usar para llamar Gmail API
```

---

## PASO 9 — Google Calendar API (opcional)

Similar a Gmail:
1. Habilitar **Google Calendar API** en Google Cloud Console
2. Agregar scope: `https://www.googleapis.com/auth/calendar`
3. En Supabase: agregar el scope adicional
4. Usar `session.provider_token` para llamar Calendar API

---

## CHECKLIST FINAL

- [ ] Supabase creado y schema ejecutado
- [ ] Google OAuth configurado en Google Cloud Console
- [ ] Google OAuth configurado en Supabase
- [ ] Repositorio GitHub creado y código pusheado
- [ ] Netlify conectado a GitHub
- [ ] Variables de entorno configuradas en Netlify
- [ ] URL de Netlify agregada a Supabase y Google OAuth
- [ ] Login con Google funcionando
- [ ] CRUD de onboarding funcionando con Supabase
- [ ] Netlify Function para AI Analysis funcionando

---

## Estructura final del proyecto

```
talentmap/
├── public/
│   └── index.html          ← App completa (standalone)
├── netlify/
│   └── functions/
│       └── ai-analyze.js   ← Proxy seguro para Anthropic API
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql  ← Schema completo
├── src/
│   └── lib/
│       └── supabase.js     ← Cliente Supabase con todos los helpers
├── .env.example            ← Plantilla de variables
├── .gitignore              ← Excluye .env y node_modules
├── netlify.toml            ← Configuración de Netlify
├── package.json
└── vite.config.js
```

---

## Troubleshooting frecuente

### "redirect_uri_mismatch" en Google OAuth
→ Verificar que la URL en Google Cloud Console coincide EXACTAMENTE con la de Supabase

### "Invalid API Key" en Supabase
→ Verificar que usas la `anon public key`, no la `service_role key`

### Las variables de entorno no aparecen en Netlify
→ Redeploy después de agregar las variables: Deploys → Trigger deploy

### CORS error en la Netlify Function
→ Verificar el header `Access-Control-Allow-Origin` en `ai-analyze.js`

### El login con Google no redirige correctamente
→ Verificar el `redirectTo` en `signInWithGoogle()` coincide con tu URL de Netlify
```

---

## Recursos útiles

- Supabase Docs: https://supabase.com/docs
- Netlify Docs: https://docs.netlify.com
- Google OAuth: https://developers.google.com/identity/protocols/oauth2
- Anthropic API: https://docs.anthropic.com
