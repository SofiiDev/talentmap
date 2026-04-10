# TalentMap 🗺️

Plataforma de Desarrollo de Carrera — HR Tech para empresas científico-tecnológicas.

## Stack
- **Frontend:** HTML/CSS/JS vanilla (sin framework) + Supabase JS SDK
- **Base de datos:** Supabase (PostgreSQL)
- **Auth:** Google OAuth vía Supabase Auth  
- **Hosting:** Netlify (deploy automático desde GitHub)
- **AI:** Anthropic Claude vía Netlify Function (API key segura, server-side)

## Features
- 👥 Gestión de empleados (CRUD)
- 🏠 **Onboarding con CRUD completo** — checklist editable inline, categorías, responsables, fechas límite, templates reutilizables
- 💬 Encuestas 1:1
- 🗺 Roadmaps de carrera
- 📊 Métricas y dashboard
- ✦ Análisis IA de perfiles (via Netlify Function)
- 🔐 Login con Google (OAuth)

## Deploy rápido

Ver **DEPLOYMENT.md** para la guía completa paso a paso.

```bash
npm install
cp .env.example .env.local
# Completar .env.local con tus credenciales
npm run dev
```

## Estructura
```
public/index.html          → App completa standalone
netlify/functions/         → Serverless functions (AI proxy)
supabase/migrations/       → Schema SQL completo
src/lib/supabase.js        → API helpers
```
