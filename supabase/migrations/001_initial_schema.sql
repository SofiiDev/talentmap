-- ================================================
-- TalentMap — Supabase Schema
-- Ejecutar en Supabase SQL Editor
-- ================================================

-- Habilitar RLS (Row Level Security)
-- Habilitar extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- TABLA: employees
-- ================================================
CREATE TABLE IF NOT EXISTS employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  lastname TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  area TEXT,
  role TEXT,
  level TEXT CHECK (level IN ('Junior','Mid','Senior','Lead','Manager','Director')),
  site TEXT,
  sector TEXT,
  date DATE,
  edu TEXT,
  skills TEXT[] DEFAULT '{}',
  notes TEXT,
  color TEXT DEFAULT '#1D6AE5',
  is_new BOOLEAN DEFAULT false,
  ai_analysis JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- ================================================
-- TABLA: onboardings
-- ================================================
CREATE TABLE IF NOT EXISTS onboardings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  start_date DATE,
  duration TEXT DEFAULT '90 días',
  mentor TEXT,
  site TEXT,
  status TEXT DEFAULT 'En proceso' CHECK (status IN ('En proceso','Completado','Pendiente inicio')),
  progress INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: onboarding_activities
-- ================================================
CREATE TABLE IF NOT EXISTS onboarding_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  onboarding_id UUID NOT NULL REFERENCES onboardings(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'General' CHECK (category IN ('General','Accesos','Documentación','Capacitación','Social','Técnico','Compliance')),
  responsible TEXT,
  due_date DATE,
  done BOOLEAN DEFAULT false,
  done_date DATE,
  order_index INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: onboarding_templates
-- ================================================
CREATE TABLE IF NOT EXISTS onboarding_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  area TEXT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS onboarding_template_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID NOT NULL REFERENCES onboarding_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'General',
  responsible TEXT,
  day_offset INTEGER DEFAULT 0,
  order_index INTEGER DEFAULT 0
);

-- ================================================
-- TABLA: surveys
-- ================================================
CREATE TABLE IF NOT EXISTS surveys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  supervisor TEXT,
  date DATE DEFAULT CURRENT_DATE,
  type TEXT DEFAULT 'Check-in mensual',
  q1 TEXT,
  q2 TEXT,
  q3 TEXT,
  q4 TEXT,
  q5 INTEGER,
  q6 TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: roadmaps
-- ================================================
CREATE TABLE IF NOT EXISTS roadmaps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  area TEXT,
  description TEXT,
  phases JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: plans (roadmaps asignados a empleados)
-- ================================================
CREATE TABLE IF NOT EXISTS plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  roadmap_id UUID NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'En curso',
  priority TEXT DEFAULT 'Media',
  progress INTEGER DEFAULT 0,
  start_date DATE,
  end_date DATE,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: training_plans
-- ================================================
CREATE TABLE IF NOT EXISTS training_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  site TEXT,
  sector TEXT,
  year INTEGER,
  type TEXT DEFAULT 'Anual',
  status TEXT DEFAULT 'Activo',
  start_date DATE,
  end_date DATE,
  goal TEXT,
  comment TEXT,
  activities JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: courses
-- ================================================
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  provider TEXT,
  category TEXT,
  duration TEXT,
  url TEXT,
  description TEXT,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TABLA: activity_log
-- ================================================
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  icon TEXT,
  text TEXT NOT NULL,
  time_label TEXT DEFAULT 'Ahora mismo',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- FUNCIÓN: actualizar updated_at automáticamente
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_onboardings_updated_at BEFORE UPDATE ON onboardings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_onboarding_activities_updated_at BEFORE UPDATE ON onboarding_activities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_training_plans_updated_at BEFORE UPDATE ON training_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- FUNCIÓN: recalcular progreso de onboarding
-- ================================================
CREATE OR REPLACE FUNCTION recalculate_onboarding_progress()
RETURNS TRIGGER AS $$
DECLARE
  total_count INTEGER;
  done_count INTEGER;
  new_progress INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM onboarding_activities WHERE onboarding_id = COALESCE(NEW.onboarding_id, OLD.onboarding_id);
  SELECT COUNT(*) INTO done_count FROM onboarding_activities WHERE onboarding_id = COALESCE(NEW.onboarding_id, OLD.onboarding_id) AND done = true;
  
  IF total_count > 0 THEN
    new_progress := ROUND((done_count::NUMERIC / total_count) * 100);
  ELSE
    new_progress := 0;
  END IF;
  
  UPDATE onboardings SET 
    progress = new_progress,
    status = CASE WHEN new_progress = 100 THEN 'Completado' ELSE status END,
    updated_at = NOW()
  WHERE id = COALESCE(NEW.onboarding_id, OLD.onboarding_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER recalc_onboarding_progress
AFTER INSERT OR UPDATE OR DELETE ON onboarding_activities
FOR EACH ROW EXECUTE FUNCTION recalculate_onboarding_progress();

-- ================================================
-- ROW LEVEL SECURITY (RLS)
-- ================================================
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboardings ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_template_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Política: usuarios autenticados pueden ver y editar todo (para MVP)
-- En producción, agregar políticas más granulares por rol/empresa

CREATE POLICY "Authenticated users full access - employees" ON employees FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - onboardings" ON onboardings FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - onboarding_activities" ON onboarding_activities FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - onboarding_templates" ON onboarding_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - onboarding_template_activities" ON onboarding_template_activities FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - surveys" ON surveys FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - roadmaps" ON roadmaps FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - plans" ON plans FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - training_plans" ON training_plans FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - courses" ON courses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access - activity_log" ON activity_log FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ================================================
-- DATOS INICIALES: template de onboarding por defecto
-- ================================================
INSERT INTO onboarding_templates (name, description, area, is_default) VALUES
('Onboarding General', 'Plan estándar para todos los nuevos ingresos', NULL, true),
('Onboarding Técnico', 'Plan para perfiles técnicos y de IT', 'Tecnología', false),
('Onboarding I+D', 'Plan para investigación y desarrollo', 'I+D', false);

-- Actividades para template general (id lo obtenemos con subquery)
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Presentación al equipo', 'Reunión de bienvenida con el equipo directo', 'Social', 'RRHH', 1, 1 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Configuración de accesos y credenciales', 'Correo, sistemas, VPN, herramientas', 'Accesos', 'IT', 1, 2 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Lectura y firma de políticas internas', 'Código de conducta, políticas de seguridad', 'Compliance', 'RRHH', 2, 3 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Reunión de alineación con supervisor', 'Expectativas, objetivos del primer trimestre', 'General', 'Supervisor', 3, 4 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Tour por las instalaciones', 'Visita guiada a las plantas y sectores', 'Social', 'RRHH', 1, 5 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Capacitación en seguridad e higiene', 'Módulo obligatorio BPL/BPF', 'Capacitación', 'SHE', 5, 6 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Entrevista de seguimiento a 30 días', 'Check-in de adaptación con RRHH', 'General', 'RRHH', 30, 7 FROM onboarding_templates WHERE is_default = true LIMIT 1;
INSERT INTO onboarding_template_activities (template_id, name, description, category, responsible, day_offset, order_index)
SELECT id, 'Evaluación de finalización de onboarding', 'Cierre formal del proceso de incorporación', 'General', 'RRHH', 90, 8 FROM onboarding_templates WHERE is_default = true LIMIT 1;
