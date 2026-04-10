import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Supabase env vars missing. Copy .env.example to .env and fill in values.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
})

// ─── AUTH ───────────────────────────────────────
export async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/`,
      scopes: 'openid email profile https://www.googleapis.com/auth/gmail.compose https://www.googleapis.com/auth/calendar',
    },
  })
  if (error) throw error
  return data
}

export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

// ─── EMPLOYEES ──────────────────────────────────
export const employeesApi = {
  getAll: async () => {
    const { data, error } = await supabase.from('employees').select('*').order('created_at', { ascending: false })
    if (error) throw error
    return data
  },
  getById: async (id) => {
    const { data, error } = await supabase.from('employees').select('*').eq('id', id).single()
    if (error) throw error
    return data
  },
  create: async (employee) => {
    const { data, error } = await supabase.from('employees').insert([employee]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('employees').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('employees').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── ONBOARDINGS ────────────────────────────────
export const onboardingsApi = {
  getAll: async () => {
    const { data, error } = await supabase
      .from('onboardings')
      .select(`*, employees(id, name, lastname, role, color, area), onboarding_activities(*)`)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },
  getById: async (id) => {
    const { data, error } = await supabase
      .from('onboardings')
      .select(`*, employees(id, name, lastname, role, color, area), onboarding_activities(*)`)
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },
  create: async (onboarding) => {
    const { data, error } = await supabase.from('onboardings').insert([onboarding]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('onboardings').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('onboardings').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── ONBOARDING ACTIVITIES ──────────────────────
export const activitiesApi = {
  getByOnboarding: async (onboardingId) => {
    const { data, error } = await supabase
      .from('onboarding_activities')
      .select('*')
      .eq('onboarding_id', onboardingId)
      .order('order_index', { ascending: true })
    if (error) throw error
    return data
  },
  create: async (activity) => {
    const { data, error } = await supabase.from('onboarding_activities').insert([activity]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('onboarding_activities').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  toggle: async (id, done) => {
    const { data, error } = await supabase
      .from('onboarding_activities')
      .update({ done, done_date: done ? new Date().toISOString().split('T')[0] : null })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('onboarding_activities').delete().eq('id', id)
    if (error) throw error
  },
  reorder: async (activities) => {
    const updates = activities.map((a, i) => ({ id: a.id, order_index: i }))
    const { error } = await supabase.from('onboarding_activities').upsert(updates)
    if (error) throw error
  },
}

// ─── ONBOARDING TEMPLATES ───────────────────────
export const templatesApi = {
  getAll: async () => {
    const { data, error } = await supabase
      .from('onboarding_templates')
      .select(`*, onboarding_template_activities(*)`)
      .order('created_at')
    if (error) throw error
    return data
  },
  create: async (template, activities) => {
    const { data: tmpl, error } = await supabase.from('onboarding_templates').insert([template]).select().single()
    if (error) throw error
    if (activities?.length) {
      const acts = activities.map((a, i) => ({ ...a, template_id: tmpl.id, order_index: i }))
      await supabase.from('onboarding_template_activities').insert(acts)
    }
    return tmpl
  },
  delete: async (id) => {
    const { error } = await supabase.from('onboarding_templates').delete().eq('id', id)
    if (error) throw error
  },
  applyToOnboarding: async (templateId, onboardingId, startDate) => {
    const { data: tmplActs } = await supabase
      .from('onboarding_template_activities')
      .select('*')
      .eq('template_id', templateId)
      .order('order_index')
    if (!tmplActs) return
    const start = new Date(startDate)
    const activities = tmplActs.map((a, i) => {
      const due = new Date(start)
      due.setDate(due.getDate() + (a.day_offset || 0))
      return {
        onboarding_id: onboardingId,
        name: a.name,
        description: a.description,
        category: a.category,
        responsible: a.responsible,
        due_date: due.toISOString().split('T')[0],
        order_index: i,
        done: false,
      }
    })
    const { error } = await supabase.from('onboarding_activities').insert(activities)
    if (error) throw error
  },
}

// ─── SURVEYS ────────────────────────────────────
export const surveysApi = {
  getAll: async () => {
    const { data, error } = await supabase
      .from('surveys')
      .select(`*, employees(name, lastname, color)`)
      .order('date', { ascending: false })
    if (error) throw error
    return data
  },
  create: async (survey) => {
    const { data, error } = await supabase.from('surveys').insert([survey]).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('surveys').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── ROADMAPS ───────────────────────────────────
export const roadmapsApi = {
  getAll: async () => {
    const { data, error } = await supabase.from('roadmaps').select('*').order('created_at')
    if (error) throw error
    return data
  },
  create: async (roadmap) => {
    const { data, error } = await supabase.from('roadmaps').insert([roadmap]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('roadmaps').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('roadmaps').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── PLANS ──────────────────────────────────────
export const plansApi = {
  getAll: async () => {
    const { data, error } = await supabase
      .from('plans')
      .select(`*, employees(name, lastname, color), roadmaps(name)`)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },
  create: async (plan) => {
    const { data, error } = await supabase.from('plans').insert([plan]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('plans').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('plans').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── TRAINING PLANS ─────────────────────────────
export const trainingPlansApi = {
  getAll: async () => {
    const { data, error } = await supabase
      .from('training_plans')
      .select(`*, employees(name, lastname)`)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },
  create: async (plan) => {
    const { data, error } = await supabase.from('training_plans').insert([plan]).select().single()
    if (error) throw error
    return data
  },
  update: async (id, updates) => {
    const { data, error } = await supabase.from('training_plans').update(updates).eq('id', id).select().single()
    if (error) throw error
    return data
  },
  delete: async (id) => {
    const { error } = await supabase.from('training_plans').delete().eq('id', id)
    if (error) throw error
  },
}

// ─── ACTIVITY LOG ───────────────────────────────
export const activityLogApi = {
  getRecent: async (limit = 30) => {
    const { data, error } = await supabase
      .from('activity_log')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    if (error) throw error
    return data
  },
  add: async (icon, text) => {
    const { error } = await supabase.from('activity_log').insert([{ icon, text }])
    if (error) console.error('Activity log error:', error)
  },
}
