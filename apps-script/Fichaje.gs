/**
 * ============================================================
 * Fichaje.gs — Módulo de fichaje digital (time clock)
 * ============================================================
 * Cumplimiento del Real Decreto-ley 8/2019 (registro de jornada).
 * Gestiona: entrada, salida, pausas, geolocalización, validación
 * por PIN, resúmenes y exportación CSV.
 * ============================================================
 */

// ─── Datos de prueba ────────────────────────────────────────

const DEMO_EMPLEADOS = [
  {id:'emp_bosco', nombre:'Bosco Blanco', email:'bosco@encopadebalon.com', pin:'0000', rol:'admin', ubicacionBaseId:'all', ubicacionBaseNombre:'Todas', activo:true},
  {id:'emp_carlos', nombre:'Carlos Ruiz', email:'carlos@encopadebalon.com', pin:'1111', rol:'manager', ubicacionBaseId:'loc_zoco', ubicacionBaseNombre:'Zoco de Pozuelo', activo:true},
  {id:'emp_maria', nombre:'María López', email:'maria@encopadebalon.com', pin:'2222', rol:'empleado', ubicacionBaseId:'loc_arturo', ubicacionBaseNombre:'CC Arturo Soria Plaza', activo:true},
  {id:'emp_pablo', nombre:'Pablo Fernández', email:'pablo@encopadebalon.com', pin:'3333', rol:'comercial', ubicacionBaseId:'loc_codeba', ubicacionBaseNombre:'CODEBA - Nave Leganés', activo:true},
  {id:'emp_laura', nombre:'Laura Martín', email:'laura@encopadebalon.com', pin:'4444', rol:'empleado', ubicacionBaseId:'loc_ancestral', ubicacionBaseNombre:'Ancestral', activo:true}
];

const DEMO_UBICACIONES = [
  {id:'loc_zoco', nombre:'Zoco de Pozuelo', direccion:'C.C. Zoco, Pozuelo de Alarcón', latitud:40.4356, longitud:-3.8125, radioPermitido:500, activo:true},
  {id:'loc_oeste', nombre:'Centro Oeste Majadahonda', direccion:'C.C. Centro Oeste, Majadahonda', latitud:40.4723, longitud:-3.8721, radioPermitido:500, activo:true},
  {id:'loc_arturo', nombre:'CC Arturo Soria Plaza', direccion:'C.C. Arturo Soria Plaza, Madrid', latitud:40.4512, longitud:-3.6389, radioPermitido:500, activo:true},
  {id:'loc_granada', nombre:'Calle Granada', direccion:'Calle Granada, Madrid', latitud:40.4168, longitud:-3.7038, radioPermitido:500, activo:true},
  {id:'loc_balboa', nombre:'Calle Núñez de Balboa', direccion:'C/ Núñez de Balboa, Madrid', latitud:40.4275, longitud:-3.6821, radioPermitido:500, activo:true},
  {id:'loc_casita', nombre:'La Casita (Claudio Coello)', direccion:'C/ Claudio Coello, Madrid', latitud:40.4282, longitud:-3.6798, radioPermitido:500, activo:true},
  {id:'loc_aravaca', nombre:'Restaurante Aravaca', direccion:'Aravaca, Madrid', latitud:40.4589, longitud:-3.8012, radioPermitido:500, activo:true},
  {id:'loc_moraleja', nombre:'Restaurante Moraleja', direccion:'La Moraleja, Alcobendas', latitud:40.4932, longitud:-3.6512, radioPermitido:500, activo:true},
  {id:'loc_rpozuelo', nombre:'Restaurante Pozuelo', direccion:'Pozuelo de Alarcón', latitud:40.4367, longitud:-3.8156, radioPermitido:500, activo:true},
  {id:'loc_ancestral', nombre:'Ancestral', direccion:'Madrid', latitud:40.4234, longitud:-3.6923, radioPermitido:500, activo:true},
  {id:'loc_brassafina', nombre:'Brassafina', direccion:'Madrid', latitud:40.4198, longitud:-3.6945, radioPermitido:500, activo:true},
  {id:'loc_margaritas', nombre:'Las Margaritas', direccion:'Madrid', latitud:40.4312, longitud:-3.7012, radioPermitido:500, activo:true},
  {id:'loc_panthera', nombre:'Panthera', direccion:'Madrid', latitud:40.4256, longitud:-3.6876, radioPermitido:500, activo:true},
  {id:'loc_rubicon', nombre:'Rubicon', direccion:'Madrid', latitud:40.4278, longitud:-3.6901, radioPermitido:500, activo:true},
  {id:'loc_codeba', nombre:'CODEBA - Nave Leganés', direccion:'Nave industrial, Leganés', latitud:40.3267, longitud:-3.7634, radioPermitido:1000, activo:true}
];

// ─── Inicialización de datos demo ───────────────────────────

function initFichajeData() {
  const ss = getSpreadsheet_() || initSheet();

  // Poblar Empleados si está vacío
  const empSheet = ss.getSheetByName('Empleados');
  if (empSheet && empSheet.getLastRow() <= 1) {
    DEMO_EMPLEADOS.forEach(function(e) {
      empSheet.appendRow([e.id, e.nombre, e.email, e.pin, e.rol, e.ubicacionBaseId, e.ubicacionBaseNombre, e.activo, new Date().toISOString()]);
    });
    // Forzar columna PIN como texto
    empSheet.getRange(2, 4, DEMO_EMPLEADOS.length, 1).setNumberFormat('@');
  }

  // Poblar Ubicaciones si está vacío
  const ubSheet = ss.getSheetByName('Ubicaciones');
  if (ubSheet && ubSheet.getLastRow() <= 1) {
    DEMO_UBICACIONES.forEach(function(u) {
      ubSheet.appendRow([u.id, u.nombre, u.direccion || '', u.latitud || '', u.longitud || '', u.radioPermitido || 500, '', u.activo]);
    });
  }
}

// ─── Validación de PIN ──────────────────────────────────────

function validarPIN(pin) {
  pin = String(pin || '').trim();
  if (!/^\d{4}$/.test(pin)) return { success: false, error: 'PIN debe ser 4 dígitos' };

  initFichajeData();
  const data = getAll('Empleados');

  for (var i = 0; i < data.length; i++) {
    var emp = data[i];
    if (String(emp.pin || '').trim() === pin && emp.activo !== false && emp.activo !== 'false') {
      return {
        success: true,
        empleado: {
          id: emp.id,
          nombre: emp.nombre,
          email: emp.email || '',
          rol: emp.rol || 'empleado',
          ubicacionBaseId: emp.ubicacionBaseId || '',
          ubicacionBaseNombre: emp.ubicacionBaseNombre || ''
        }
      };
    }
  }

  return { success: false, error: 'PIN incorrecto' };
}

// ─── Registro de fichaje ────────────────────────────────────

function registrarFichaje(data) {
  var empleadoId = String(data.empleadoId || '').trim();
  var tipo = String(data.tipo || '').trim();
  if (!empleadoId) return { success: false, error: 'Empleado requerido' };
  if (['entrada', 'salida', 'pausa_inicio', 'pausa_fin'].indexOf(tipo) === -1) {
    return { success: false, error: 'Tipo inválido: ' + tipo };
  }

  var fichaje = {
    id: Utilities.getUuid(),
    empleadoId: empleadoId,
    empleadoNombre: data.empleadoNombre || '',
    tipo: tipo,
    timestamp: data.timestamp || new Date().toISOString(),
    latitud: data.latitud || '',
    longitud: data.longitud || '',
    precision: data.precision || '',
    ubicacionId: data.ubicacionId || '',
    ubicacionNombre: data.ubicacionNombre || '',
    metodo: data.metodo || 'app',
    dispositivo: data.dispositivo || '',
    userAgent: data.userAgent || ''
  };

  upsert('FichajesDigital', fichaje);

  try {
    var emoji = tipo === 'entrada' ? '🟢' : tipo === 'salida' ? '🔴' : '⏸️';
    logActivity_(emoji, fichaje.empleadoNombre, 'fichó ' + tipo, fichaje.ubicacionNombre || '', fichaje.metodo);
  } catch (e) {}

  return { success: true, fichaje: fichaje };
}

// ─── Estado actual del empleado ─────────────────────────────

function getEstadoFichaje(empleadoId) {
  empleadoId = String(empleadoId || '').trim();
  var all = getAll('FichajesDigital');
  var today = new Date();
  today.setHours(0, 0, 0, 0);

  var hoy = all.filter(function(f) {
    return String(f.empleadoId) === empleadoId && new Date(f.timestamp) >= today;
  }).sort(function(a, b) { return new Date(a.timestamp) - new Date(b.timestamp); });

  var entrada = null, salida = null, pausas = [], enPausa = false;
  hoy.forEach(function(f) {
    if (f.tipo === 'entrada') entrada = f;
    if (f.tipo === 'salida') salida = f;
    if (f.tipo === 'pausa_inicio') { pausas.push({ inicio: f }); enPausa = true; }
    if (f.tipo === 'pausa_fin' && pausas.length) { pausas[pausas.length - 1].fin = f; enPausa = false; }
  });

  var minutesTrabajados = 0;
  if (entrada) {
    var fin = salida ? new Date(salida.timestamp) : new Date();
    minutesTrabajados = (fin - new Date(entrada.timestamp)) / 60000;
    pausas.forEach(function(p) {
      if (p.inicio && p.fin) {
        minutesTrabajados -= (new Date(p.fin.timestamp) - new Date(p.inicio.timestamp)) / 60000;
      }
    });
  }

  return {
    fichadoHoy: !!entrada,
    trabajando: !!entrada && !salida,
    enPausa: enPausa,
    entrada: entrada,
    salida: salida,
    pausas: pausas,
    minutesTrabajados: Math.max(0, Math.round(minutesTrabajados)),
    fichajes: hoy
  };
}

// ─── Fichajes de un empleado por rango ──────────────────────

function getFichajesEmpleado(empleadoId, desde, hasta) {
  var all = getAll('FichajesDigital');
  var d = desde ? new Date(desde) : new Date(Date.now() - 30 * 864e5);
  var h = hasta ? new Date(hasta) : new Date();
  h.setHours(23, 59, 59, 999);

  return all.filter(function(f) {
    var t = new Date(f.timestamp);
    return String(f.empleadoId) === String(empleadoId) && t >= d && t <= h;
  }).sort(function(a, b) { return new Date(b.timestamp) - new Date(a.timestamp); });
}

// ─── Fichajes por ubicación ─────────────────────────────────

function getFichajesUbicacion(ubicacionId, desde, hasta) {
  var all = getAll('FichajesDigital');
  var d = desde ? new Date(desde) : new Date(Date.now() - 7 * 864e5);
  var h = hasta ? new Date(hasta) : new Date();
  h.setHours(23, 59, 59, 999);

  return all.filter(function(f) {
    var t = new Date(f.timestamp);
    return String(f.ubicacionId) === String(ubicacionId) && t >= d && t <= h;
  }).sort(function(a, b) { return new Date(b.timestamp) - new Date(a.timestamp); });
}

// ─── Resumen semanal ────────────────────────────────────────

function getResumenSemanal(empleadoId) {
  var now = new Date();
  var lunes = new Date(now);
  lunes.setDate(now.getDate() - ((now.getDay() + 6) % 7));
  lunes.setHours(0, 0, 0, 0);

  var fichajes = getFichajesEmpleado(empleadoId, lunes.toISOString(), now.toISOString());
  var dias = {};

  fichajes.forEach(function(f) {
    var dia = f.timestamp.slice(0, 10);
    if (!dias[dia]) dias[dia] = [];
    dias[dia].push(f);
  });

  var totalMinutos = 0;
  var diasCompletos = 0;
  var diasIncompletos = 0;

  Object.keys(dias).forEach(function(dia) {
    var df = dias[dia];
    var entrada = df.find(function(f) { return f.tipo === 'entrada'; });
    var salida = df.find(function(f) { return f.tipo === 'salida'; });
    if (entrada && salida) {
      totalMinutos += (new Date(salida.timestamp) - new Date(entrada.timestamp)) / 60000;
      diasCompletos++;
    } else if (entrada) {
      diasIncompletos++;
    }
  });

  return {
    totalHoras: Math.round(totalMinutos / 60 * 10) / 10,
    promedioDiario: diasCompletos > 0 ? Math.round(totalMinutos / diasCompletos / 60 * 10) / 10 : 0,
    diasTrabajados: Object.keys(dias).length,
    diasCompletos: diasCompletos,
    diasIncompletos: diasIncompletos,
    desde: lunes.toISOString(),
    hasta: now.toISOString()
  };
}

// ─── Resumen mensual ────────────────────────────────────────

function getResumenMensual(empleadoId, mes, anio) {
  mes = parseInt(mes || new Date().getMonth() + 1);
  anio = parseInt(anio || new Date().getFullYear());

  var desde = new Date(anio, mes - 1, 1);
  var hasta = new Date(anio, mes, 0, 23, 59, 59);

  var fichajes = getFichajesEmpleado(empleadoId, desde.toISOString(), hasta.toISOString());
  var dias = {};

  fichajes.forEach(function(f) {
    var dia = parseInt(f.timestamp.slice(8, 10));
    if (!dias[dia]) dias[dia] = { estado: 'sin_fichar', fichajes: [] };
    dias[dia].fichajes.push(f);
  });

  Object.keys(dias).forEach(function(dia) {
    var df = dias[dia];
    var hasEntrada = df.fichajes.some(function(f) { return f.tipo === 'entrada'; });
    var hasSalida = df.fichajes.some(function(f) { return f.tipo === 'salida'; });
    if (hasEntrada && hasSalida) df.estado = 'completo';
    else if (hasEntrada) df.estado = 'incompleto';
  });

  return { mes: mes, anio: anio, dias: dias };
}

// ─── Exportar CSV ───────────────────────────────────────────

function exportCSVFichajes(filtros) {
  var all = getAll('FichajesDigital');
  var desde = filtros.desde ? new Date(filtros.desde) : new Date(Date.now() - 30 * 864e5);
  var hasta = filtros.hasta ? new Date(filtros.hasta) : new Date();
  hasta.setHours(23, 59, 59, 999);

  var filtered = all.filter(function(f) {
    var t = new Date(f.timestamp);
    if (t < desde || t > hasta) return false;
    if (filtros.ubicacionId && String(f.ubicacionId) !== String(filtros.ubicacionId)) return false;
    if (filtros.empleadoId && String(f.empleadoId) !== String(filtros.empleadoId)) return false;
    return true;
  });

  var header = 'ID,Empleado,Nombre,Tipo,Fecha,Hora,Latitud,Longitud,Precisión,Ubicación,Método\n';
  var rows = filtered.map(function(f) {
    var d = new Date(f.timestamp);
    return [
      f.id,
      f.empleadoId,
      '"' + (f.empleadoNombre || '') + '"',
      f.tipo,
      d.toLocaleDateString('es-ES'),
      d.toLocaleTimeString('es-ES'),
      f.latitud || '',
      f.longitud || '',
      f.precision || '',
      '"' + (f.ubicacionNombre || '') + '"',
      f.metodo || 'app'
    ].join(',');
  }).join('\n');

  return { csv: header + rows, count: filtered.length };
}

// ─── Todas las ubicaciones ──────────────────────────────────

function getUbicaciones() {
  initFichajeData();
  return getAll('Ubicaciones').filter(function(u) { return u.activo !== false && u.activo !== 'false'; });
}

// ─── Todos los empleados ────────────────────────────────────

function getEmpleadosFichaje() {
  initFichajeData();
  return getAll('Empleados').filter(function(e) { return e.activo !== false && e.activo !== 'false'; }).map(function(e) {
    return { id: e.id, nombre: e.nombre, email: e.email, rol: e.rol, ubicacionBaseId: e.ubicacionBaseId, ubicacionBaseNombre: e.ubicacionBaseNombre };
  });
}

// ─── Fichajes de todos los empleados hoy (para manager) ─────

function getFichajesHoy() {
  var all = getAll('FichajesDigital');
  var today = new Date();
  today.setHours(0, 0, 0, 0);

  return all.filter(function(f) {
    return new Date(f.timestamp) >= today;
  }).sort(function(a, b) { return new Date(b.timestamp) - new Date(a.timestamp); });
}
