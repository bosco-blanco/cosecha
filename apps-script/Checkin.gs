/**
 * ============================================================
 * Checkin.gs - Fichajes laborales + gestión de usuarios/roles
 * ============================================================
 * Dos conceptos:
 *  1. Usuarios: email → rol (admin / comercial / equipo)
 *  2. Fichajes: registro de entrada/salida diario con GPS opcional
 *
 * El rol determina la experiencia de la app:
 *  - admin:     ve todo (incluye fichas nuevas de clientes)
 *  - comercial: foco CRM (clientes, pipeline, reuniones geolocalizadas)
 *  - equipo:    foco gestión de proyectos (tableros, tareas)
 *
 * Los usuarios se crean automáticamente la primera vez que inician
 * sesión (desde Auth.gs → verifyAuthCode). Rol por defecto según email.
 * ============================================================
 */

// ─── Configuración ──────────────────────────────────────────

/**
 * Reglas de rol por email. Se pueden sobreescribir desde la pestaña
 * "Usuarios" editando la columna "rol" a mano.
 */
const ROLE_RULES = {
  // Admin (incluye a sí mismo)
  'bosco@encopadebalon.com': 'admin',
  // Comerciales
  'saul@encopadebalon.com': 'comercial',
  // El resto → 'equipo' por defecto
};

const DEFAULT_ROLE = 'equipo';
const AVATAR_COLORS = ['#9B2C3E', '#1B9E5A', '#2B7BD4', '#7B5EA7', '#D97C1E', '#C4952E'];

// Duración máxima de la jornada laboral en ms (8 horas)
const WORKDAY_MS = 8 * 60 * 60 * 1000;

// ─── Usuarios ───────────────────────────────────────────────

/**
 * Obtiene el perfil del usuario (o lo crea si es la primera vez).
 * Llamado desde Auth.gs al verificar código.
 * @param {string} email
 * @returns {Object} { email, nombre, rol, departamento, avatar, color }
 */
function getOrCreateUser_(email) {
  email = String(email || '').toLowerCase().trim();
  if (!email) return null;

  const sheet = getTabSheet_('Usuarios');
  const data = sheet.getDataRange().getValues();

  // Buscar usuario existente
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).toLowerCase() === email) {
      // Actualizar última actividad
      sheet.getRange(i + 1, 8).setValue(new Date().toISOString());
      return {
        email: data[i][0],
        nombre: data[i][1],
        rol: data[i][2] || DEFAULT_ROLE,
        departamento: data[i][3] || '',
        avatar: data[i][4] || '',
        color: data[i][5] || AVATAR_COLORS[0]
      };
    }
  }

  // Crear nuevo usuario
  const rol = ROLE_RULES[email] || DEFAULT_ROLE;
  const nombre = emailToName_(email);
  const color = AVATAR_COLORS[Math.floor(Math.random() * AVATAR_COLORS.length)];
  const avatar = nombre.split(' ').map(p => p.charAt(0)).join('').slice(0, 2).toUpperCase();
  const now = new Date().toISOString();

  sheet.appendRow([email, nombre, rol, '', avatar, color, now, now]);

  return { email, nombre, rol, departamento: '', avatar, color };
}

/**
 * Devuelve todos los usuarios del equipo.
 */
function listUsers() {
  const data = getAll('Usuarios');
  return data.map(u => ({
    email: u.email,
    nombre: u.nombre,
    rol: u.rol || DEFAULT_ROLE,
    departamento: u.departamento || '',
    avatar: u.avatar || '',
    color: u.color || AVATAR_COLORS[0],
    ultimaActividad: u.ultimaActividad || ''
  }));
}

/**
 * Actualiza los datos de un usuario (solo admin).
 * @param {Object} body { email, nombre?, rol?, departamento? }
 */
function updateUser(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const sheet = getTabSheet_('Usuarios');
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).toLowerCase() === email) {
      if (body.nombre !== undefined)       sheet.getRange(i + 1, 2).setValue(body.nombre);
      if (body.rol !== undefined)          sheet.getRange(i + 1, 3).setValue(body.rol);
      if (body.departamento !== undefined) sheet.getRange(i + 1, 4).setValue(body.departamento);
      if (body.color !== undefined)        sheet.getRange(i + 1, 6).setValue(body.color);
      return { success: true };
    }
  }
  return { success: false, error: 'Usuario no encontrado' };
}

/**
 * Invita a un nuevo usuario (lo crea en la tabla antes del primer login).
 */
function inviteUser(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };
  const domain = (typeof getConfig_ === 'function' && getConfig_('AUTH_DOMAIN')) || AUTH_DOMAIN_DEFAULT;
  if (!email.endsWith('@' + domain)) {
    return { success: false, error: 'Debe ser email @' + domain };
  }

  const sheet = getTabSheet_('Usuarios');
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).toLowerCase() === email) {
      return { success: false, error: 'El usuario ya existe' };
    }
  }

  const rol = body.rol || DEFAULT_ROLE;
  const nombre = body.nombre || emailToName_(email);
  const color = body.color || AVATAR_COLORS[Math.floor(Math.random() * AVATAR_COLORS.length)];
  const avatar = nombre.split(' ').map(p => p.charAt(0)).join('').slice(0, 2).toUpperCase();
  const now = new Date().toISOString();

  sheet.appendRow([email, nombre, rol, body.departamento || '', avatar, color, now, '']);
  return { success: true, user: { email, nombre, rol, departamento: body.departamento || '', avatar, color } };
}

/**
 * Elimina un usuario (solo admin, no puede eliminar al último admin).
 */
function deleteUser(email) {
  email = String(email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const sheet = getTabSheet_('Usuarios');
  const data = sheet.getDataRange().getValues();

  // Contar admins
  let adminCount = 0;
  for (let i = 1; i < data.length; i++) {
    if (data[i][2] === 'admin') adminCount++;
  }

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]).toLowerCase() === email) {
      if (data[i][2] === 'admin' && adminCount <= 1) {
        return { success: false, error: 'No se puede eliminar al último admin' };
      }
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, error: 'Usuario no encontrado' };
}

/**
 * Obtiene los fichajes de todos los usuarios (solo admin).
 */
function getAllCheckinsToday() {
  const all = getAll('Fichajes');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today.getTime() + 864e5);

  return all.filter(f => {
    const d = new Date(f.timestamp);
    return d >= today && d < tomorrow;
  });
}

// ─── Fichajes ───────────────────────────────────────────────

/**
 * Registra un fichaje de entrada o salida.
 * @param {Object} body { email, tipo: 'entrada'|'salida', lat, lng, direccion, nota }
 * @returns {Object} { success, fichaje }
 */
function registerCheckin(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const tipo = body.tipo === 'salida' ? 'salida' : 'entrada';
  const now = new Date();
  const id = Utilities.getUuid();

  // No permitir doble entrada el mismo día
  const today = getCheckinsToday(email);
  if (tipo === 'entrada' && today.some(f => f.tipo === 'entrada')) {
    return { success: false, error: 'Ya has fichado la entrada hoy' };
  }
  if (tipo === 'salida' && !today.some(f => f.tipo === 'entrada')) {
    return { success: false, error: 'Debes fichar entrada primero' };
  }

  const fichaje = {
    id: id,
    email: email,
    tipo: tipo,
    timestamp: now.toISOString(),
    lat: body.lat || '',
    lng: body.lng || '',
    direccion: body.direccion || '',
    nota: body.nota || ''
  };

  upsert('Fichajes', fichaje);

  // Al fichar salida, invalidar sesiones de jornada (corte limpio)
  if (tipo === 'salida') {
    try { invalidateWorkdaySessions(email); } catch (e) {}
  }

  try {
    const emoji = tipo === 'entrada' ? '🟢' : '🔴';
    logActivity_(emoji, emailToName_(email), 'fichó', tipo, body.direccion || '');
  } catch (e) {}

  return { success: true, fichaje: fichaje };
}

/**
 * Devuelve los fichajes de hoy para un usuario.
 */
function getCheckinsToday(email) {
  email = String(email || '').toLowerCase().trim();
  const all = getAll('Fichajes');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today.getTime() + 864e5);

  return all.filter(f => {
    if (String(f.email).toLowerCase() !== email) return false;
    const d = new Date(f.timestamp);
    return d >= today && d < tomorrow;
  });
}

/**
 * Historial de fichajes de un usuario (últimos N días).
 */
function getCheckinHistory(email, days) {
  email = String(email || '').toLowerCase().trim();
  const n = parseInt(days, 10) || 30;
  const all = getAll('Fichajes');
  const cutoff = new Date(Date.now() - n * 864e5);

  return all
    .filter(f => String(f.email).toLowerCase() === email && new Date(f.timestamp) >= cutoff)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
}

/**
 * Estado actual del usuario (¿ha fichado? ¿entrada/salida?)
 * Incluye descansos del día y tiempo de jornada transcurrido.
 */
function getCheckinStatus(email) {
  const today = getCheckinsToday(email);
  const entrada = today.find(f => f.tipo === 'entrada');
  const salida = today.find(f => f.tipo === 'salida');
  const breaks = getBreaksToday(email);
  const openBreak = breaks.find(b => !b.fin);
  let breakMinutes = 0;
  breaks.forEach(b => { if (b.duracionMin) breakMinutes += +b.duracionMin; });

  let workedMs = 0;
  if (entrada) {
    const endMs = salida ? new Date(salida.timestamp).getTime() : Date.now();
    workedMs = endMs - new Date(entrada.timestamp).getTime() - (breakMinutes * 60000);
  }

  return {
    fichadoHoy: !!entrada,
    dentro: !!entrada && !salida,
    enDescanso: !!openBreak,
    entrada: entrada || null,
    salida: salida || null,
    descansos: breaks,
    descansoAbierto: openBreak || null,
    minutosDescanso: breakMinutes,
    msTrabajados: workedMs,
    hoy: today,
    jornadaMaxMs: WORKDAY_MS
  };
}

// ─── Descansos ──────────────────────────────────────────────

/**
 * Inicia un descanso. Solo se puede si hay entrada y no hay otro descanso abierto.
 */
function startBreak(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const status = getCheckinStatus(email);
  if (!status.dentro) return { success: false, error: 'Debes fichar entrada primero' };
  if (status.enDescanso) return { success: false, error: 'Ya tienes un descanso en curso' };

  const fichaje = {
    id: Utilities.getUuid(),
    email: email,
    fecha: new Date().toISOString().slice(0, 10),
    inicio: new Date().toISOString(),
    fin: '',
    duracionMin: '',
    motivo: body.motivo || 'Descanso'
  };
  upsert('Descansos', fichaje);

  try {
    logActivity_('☕', emailToName_(email), 'inició descanso', body.motivo || 'Descanso', '');
  } catch (e) {}

  return { success: true, descanso: fichaje };
}

/**
 * Finaliza el descanso abierto del usuario.
 */
function endBreak(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const sheet = getTabSheet_('Descansos');
  const data = sheet.getDataRange().getValues();
  const now = new Date();

  for (let i = data.length - 1; i >= 1; i--) {
    if (String(data[i][1]).toLowerCase() === email && !data[i][4]) {
      const inicio = new Date(data[i][3]);
      const durMin = Math.round((now - inicio) / 60000);
      sheet.getRange(i + 1, 5).setValue(now.toISOString());
      sheet.getRange(i + 1, 6).setValue(durMin);

      try {
        logActivity_('▶️', emailToName_(email), 'volvió del descanso', '', durMin + ' min');
      } catch (e) {}

      return { success: true, duracionMin: durMin };
    }
  }
  return { success: false, error: 'No hay descanso abierto' };
}

/**
 * Descansos del usuario hoy.
 */
function getBreaksToday(email) {
  email = String(email || '').toLowerCase().trim();
  const today = new Date().toISOString().slice(0, 10);
  const all = getAll('Descansos');
  return all.filter(b => String(b.email).toLowerCase() === email && b.fecha === today);
}

// ─── Auto-cierre de jornada ─────────────────────────────────

/**
 * Cierra automáticamente las jornadas que lleven más de 8h abiertas.
 * Se debe programar como trigger cada 30 minutos.
 * Busca entradas sin salida y si han pasado más de WORKDAY_MS, crea la salida auto.
 */
function autoCloseWorkdays() {
  const allFichajes = getAll('Fichajes');
  const now = new Date();
  const cutoff = now.getTime() - WORKDAY_MS;

  // Agrupar por email+fecha
  const byUserDay = {};
  allFichajes.forEach(f => {
    const day = String(f.timestamp).slice(0, 10);
    const key = f.email + '|' + day;
    if (!byUserDay[key]) byUserDay[key] = { entrada: null, salida: null, email: f.email, day: day };
    if (f.tipo === 'entrada') byUserDay[key].entrada = f;
    if (f.tipo === 'salida')  byUserDay[key].salida = f;
  });

  let closed = 0;
  Object.keys(byUserDay).forEach(key => {
    const { entrada, salida, email } = byUserDay[key];
    if (entrada && !salida) {
      const entradaMs = new Date(entrada.timestamp).getTime();
      if (entradaMs < cutoff) {
        // Jornada abierta hace más de 8h → cerrar automáticamente
        const fichaje = {
          id: Utilities.getUuid(),
          email: email,
          tipo: 'salida',
          timestamp: new Date(entradaMs + WORKDAY_MS).toISOString(),
          lat: '',
          lng: '',
          direccion: '',
          nota: 'Auto-cierre al cumplir jornada de 8h'
        };
        upsert('Fichajes', fichaje);
        try {
          logActivity_('🌙', emailToName_(email), 'auto-cierre', 'jornada 8h', '');
        } catch (e) {}
        closed++;
      }
    }
  });

  return { cerradas: closed, checked: Object.keys(byUserDay).length };
}

// ─── Helpers ────────────────────────────────────────────────

function getTabSheet_(tabName) {
  const ss = getSpreadsheet_() || initSheet();
  return ss.getSheetByName(tabName);
}
