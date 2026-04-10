-- ================================================
-- MIGRACIÓN 002: Cursos, Asignaciones, Entrevistas
-- ================================================

-- Asignaciones de cursos a empleados
CREATE TABLE IF NOT EXISTS employee_courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  roadmap_id UUID REFERENCES roadmaps(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'Pendiente'
    CHECK (status IN ('Pendiente','En curso','Completado','Cancelado')),
  assigned_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  completed_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, course_id)
);

-- Entrevistas de desarrollo profesional
CREATE TABLE IF NOT EXISTS interviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  interviewer TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  type TEXT NOT NULL DEFAULT 'Desarrollo Profesional'
    CHECK (type IN ('Desarrollo Profesional','1:1 Seguimiento','Evaluación 360','Plan de Carrera','Feedback Anual')),
  strengths TEXT,
  improvement_areas TEXT,
  career_goals TEXT,
  skills_to_develop TEXT,
  support_needed TEXT,
  achievements TEXT,
  agreed_actions TEXT,
  next_review_date DATE,
  motivation_score INTEGER CHECK (motivation_score BETWEEN 1 AND 10),
  engagement_score INTEGER CHECK (engagement_score BETWEEN 1 AND 10),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE employee_courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth_employee_courses" ON employee_courses
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth_interviews" ON interviews
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
