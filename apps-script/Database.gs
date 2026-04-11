/**
 * ============================================================
 * Cosecha CRM - Database.gs
 * Operaciones CRUD sobre Google Sheets.
 * La hoja actúa como base de datos relacional simple.
 * ============================================================
 */

// ─── Constantes ─────────────────────────────────────────────
const SHEET_NAME = 'Cosecha CRM';

/**
 * Definición de las pestañas y sus columnas.
 * El orden de las columnas determina el orden en la hoja.
 */
const TAB_SCHEMA = {
  'Usuarios':       ['email', 'nombre', 'rol', 'departamento', 'avatar', 'color', 'creado', 'ultimaActividad', 'loginCode'],
  'Fichajes':       ['id', 'email', 'tipo', 'timestamp', 'lat', 'lng', 'direccion', 'nota'],
  'Descansos':      ['id', 'email', 'fecha', 'inicio', 'fin', 'duracionMin', 'motivo'],
  'Consentimientos':['id', 'email', 'version', 'aceptadoEn', 'items', 'userAgent', 'ip'],
  'Documentos':     ['id', 'email', 'titulo', 'tipo', 'driveFileId', 'driveUrl', 'estado', 'enviadoPor', 'enviadoEn', 'firmadoEn', 'nota', 'firmaNombre', 'firmaIp', 'firmaLat', 'firmaLng', 'firmaDireccion', 'firmaUserAgent', 'firmaHash'],
  'Contactos':      ['id', 'nombre', 'email', 'telefono', 'empresa', 'tipo', 'etiquetas', 'notas', 'ultimoContacto', 'creado', 'creadoPor'],
  'Deals':          ['id', 'titulo', 'contactoId', 'contactoNombre', 'valor', 'etapa', 'probabilidad', 'cierreEsperado', 'asignado', 'notas', 'creado'],
  'Tareas':         ['id', 'titulo', 'descripcion', 'columna', 'prioridad', 'etiqueta', 'fechaLimite', 'asignados', 'proyecto', 'creado', 'completado'],
  'Reuniones':      ['id', 'titulo', 'fecha', 'duracion', 'ubicacion', 'lat', 'lng', 'direccion', 'canal', 'asistentes', 'clienteId', 'clienteNombre', 'tipoReunion', 'palabras', 'resumen', 'puntosClave', 'acciones', 'notasGranola', 'driveFileId', 'compartidoCon', 'creado'],
  'Actividad':      ['id', 'icono', 'quien', 'accion', 'que', 'detalle', 'timestamp'],
  'Config':         ['clave', 'valor']
};

// ─── Inicialización ─────────────────────────────────────────

/**
 * Crea la hoja de cálculo y todas las pestañas si no existen.
 * Se ejecuta automáticamente en cada petición.
 * @returns {Spreadsheet} La hoja de cálculo.
 */
function initSheet() {
  let ss = getSpreadsheet_();

  // Si no existe, crear la hoja
  if (!ss) {
    ss = SpreadsheetApp.create(SHEET_NAME);
    // Guardar el ID en las propiedades del script para futuras referencias
    PropertiesService.getScriptProperties().setProperty('SHEET_ID', ss.getId());
    Logger.log('Hoja de cálculo creada: ' + ss.getUrl());
  }

  // Crear cada pestaña si no existe
  Object.keys(TAB_SCHEMA).forEach(function(tabName) {
    let sheet = ss.getSheetByName(tabName);
    if (!sheet) {
      sheet = ss.insertSheet(tabName);
      // Escribir cabeceras
      const headers = TAB_SCHEMA[tabName];
      sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
      // Formato de cabecera: negrita y color de fondo
      sheet.getRange(1, 1, 1, headers.length)
        .setFontWeight('bold')
        .setBackground('#722F37')  // Color vino tinto 🍷
        .setFontColor('#FFFFFF');
      // Congelar la primera fila
      sheet.setFrozenRows(1);
      Logger.log('Pestaña creada: ' + tabName);
    }
  });

  // Eliminar la hoja por defecto "Hoja 1" / "Sheet1" si existe y hay otras pestañas
  const defaultNames = ['Hoja 1', 'Sheet1', 'Sheet 1'];
  defaultNames.forEach(function(name) {
    const defSheet = ss.getSheetByName(name);
    if (defSheet && ss.getSheets().length > 1) {
      try { ss.deleteSheet(defSheet); } catch (e) { /* ignorar */ }
    }
  });

  return ss;
}

/**
 * Obtiene la hoja de cálculo existente o null si no se ha creado.
 * Busca primero por ID guardado en propiedades, luego por nombre.
 * @returns {Spreadsheet|null}
 */
function getSpreadsheet_() {
  // Intentar por ID guardado
  const savedId = PropertiesService.getScriptProperties().getProperty('SHEET_ID');
  if (savedId) {
    try {
      return SpreadsheetApp.openById(savedId);
    } catch (e) {
      // El ID ya no es válido, limpiar
      PropertiesService.getScriptProperties().deleteProperty('SHEET_ID');
    }
  }

  // Buscar por nombre en Drive
  const files = DriveApp.getFilesByName(SHEET_NAME);
  if (files.hasNext()) {
    const file = files.next();
    const ss = SpreadsheetApp.openById(file.getId());
    PropertiesService.getScriptProperties().setProperty('SHEET_ID', ss.getId());
    return ss;
  }

  return null;
}

/**
 * Obtiene una pestaña específica de la hoja de cálculo.
 * @param {string} tabName - Nombre de la pestaña.
 * @returns {Sheet}
 */
function getSheet_(tabName) {
  const ss = getSpreadsheet_();
  if (!ss) throw new Error('La hoja de cálculo no existe. Ejecuta initSheet() primero.');
  const sheet = ss.getSheetByName(tabName);
  if (!sheet) throw new Error('La pestaña "' + tabName + '" no existe.');
  return sheet;
}

// ─── Operaciones CRUD ───────────────────────────────────────

/**
 * Obtiene todos los registros de una pestaña como array de objetos.
 * @param {string} tab - Nombre de la pestaña.
 * @returns {Object[]} Array de objetos con las columnas como claves.
 */
function getAll(tab) {
  const sheet = getSheet_(tab);
  const data  = sheet.getDataRange().getValues();

  if (data.length <= 1) return []; // Solo cabeceras o vacío

  const headers = data[0];
  const rows    = [];

  for (var i = 1; i < data.length; i++) {
    var obj = {};
    for (var j = 0; j < headers.length; j++) {
      obj[headers[j]] = data[i][j];
    }
    rows.push(obj);
  }

  return rows;
}

/**
 * Obtiene un registro por su ID.
 * @param {string} tab - Nombre de la pestaña.
 * @param {string} id - Identificador único del registro.
 * @returns {Object|null} El registro encontrado o null.
 */
function getById(tab, id) {
  const sheet = getSheet_(tab);
  const data  = sheet.getDataRange().getValues();

  if (data.length <= 1) return null;

  const headers  = data[0];
  const idCol    = headers.indexOf('id');
  // Para la pestaña Config, buscar por "clave" en lugar de "id"
  const searchCol = (tab === 'Config') ? headers.indexOf('clave') : idCol;

  if (searchCol === -1) return null;

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][searchCol]) === String(id)) {
      var obj = {};
      for (var j = 0; j < headers.length; j++) {
        obj[headers[j]] = data[i][j];
      }
      return obj;
    }
  }

  return null;
}

/**
 * Crea o actualiza un registro. Si el objeto tiene un "id" que ya existe, actualiza;
 * de lo contrario, crea uno nuevo con un UUID.
 * @param {string} tab - Nombre de la pestaña.
 * @param {Object} data - Datos del registro.
 * @returns {Object} El registro creado/actualizado con su id.
 */
function upsert(tab, data) {
  const sheet   = getSheet_(tab);
  const values  = sheet.getDataRange().getValues();
  const headers = values[0] || TAB_SCHEMA[tab];
  const schema  = TAB_SCHEMA[tab];

  // Determinar la columna de búsqueda (id o clave para Config)
  const searchKey = (tab === 'Config') ? 'clave' : 'id';
  const searchCol = headers.indexOf(searchKey);

  // Si no tiene id (y no es Config), generar uno nuevo
  if (searchKey === 'id' && !data.id) {
    data.id = Utilities.getUuid();
  }

  // Añadir fecha de creación si es nuevo y el campo existe en el esquema
  if (schema.indexOf('creado') !== -1 && !data.creado) {
    data.creado = new Date().toISOString();
  }

  // Serializar arrays y objetos a JSON para almacenar en celdas
  Object.keys(data).forEach(function(key) {
    if (Array.isArray(data[key]) || (typeof data[key] === 'object' && data[key] !== null && !(data[key] instanceof Date))) {
      data[key] = JSON.stringify(data[key]);
    }
  });

  // Buscar si ya existe
  const searchValue = data[searchKey];
  var existingRow = -1;

  if (searchValue) {
    for (var i = 1; i < values.length; i++) {
      if (String(values[i][searchCol]) === String(searchValue)) {
        existingRow = i + 1; // +1 porque getRange usa índices desde 1
        break;
      }
    }
  }

  // Construir la fila según el esquema
  var row = schema.map(function(col) {
    if (data[col] !== undefined && data[col] !== null) {
      return data[col];
    }
    // Si estamos actualizando, mantener el valor existente
    if (existingRow > 0) {
      var colIndex = headers.indexOf(col);
      return colIndex >= 0 ? values[existingRow - 1][colIndex] : '';
    }
    return '';
  });

  if (existingRow > 0) {
    // Actualizar fila existente
    sheet.getRange(existingRow, 1, 1, row.length).setValues([row]);
  } else {
    // Insertar nueva fila
    sheet.appendRow(row);
  }

  // Devolver el objeto completo
  var result = {};
  schema.forEach(function(col, idx) {
    result[col] = row[idx];
  });

  return result;
}

/**
 * Elimina un registro por su ID.
 * @param {string} tab - Nombre de la pestaña.
 * @param {string} id - Identificador del registro a eliminar.
 * @returns {Object} Confirmación de eliminación.
 */
function deleteRow(tab, id) {
  const sheet   = getSheet_(tab);
  const values  = sheet.getDataRange().getValues();
  const headers = values[0];

  const searchKey = (tab === 'Config') ? 'clave' : 'id';
  const searchCol = headers.indexOf(searchKey);

  if (searchCol === -1) {
    return { deleted: false, message: 'Columna "' + searchKey + '" no encontrada en ' + tab };
  }

  for (var i = 1; i < values.length; i++) {
    if (String(values[i][searchCol]) === String(id)) {
      sheet.deleteRow(i + 1); // +1 por índice basado en 1
      return { deleted: true, id: id, tab: tab };
    }
  }

  return { deleted: false, message: 'Registro con ' + searchKey + '="' + id + '" no encontrado en ' + tab };
}

/**
 * Busca registros que coincidan con un texto en cualquier columna.
 * @param {string} tab - Nombre de la pestaña.
 * @param {string} query - Texto de búsqueda (insensible a mayúsculas).
 * @returns {Object[]} Registros que coinciden con la búsqueda.
 */
function search(tab, query) {
  if (!query || query.trim() === '') return getAll(tab);

  const sheet = getSheet_(tab);
  const data  = sheet.getDataRange().getValues();

  if (data.length <= 1) return [];

  const headers = data[0];
  const q       = query.toLowerCase();
  const results = [];

  for (var i = 1; i < data.length; i++) {
    var match = false;
    for (var j = 0; j < data[i].length; j++) {
      if (String(data[i][j]).toLowerCase().indexOf(q) !== -1) {
        match = true;
        break;
      }
    }
    if (match) {
      var obj = {};
      for (var j = 0; j < headers.length; j++) {
        obj[headers[j]] = data[i][j];
      }
      results.push(obj);
    }
  }

  return results;
}

/**
 * Calcula estadísticas para el dashboard.
 * Devuelve KPIs clave del CRM.
 * @returns {Object} Estadísticas del dashboard.
 */
function getDashboardStats() {
  const contactos = getAll('Contactos');
  const deals     = getAll('Deals');
  const tareas    = getAll('Tareas');
  const reuniones = getAll('Reuniones');
  const actividad = getAll('Actividad');

  // --- Contactos ---
  const totalContactos   = contactos.length;
  const contactosPorTipo = {};
  contactos.forEach(function(c) {
    var tipo = c.tipo || 'sin-tipo';
    contactosPorTipo[tipo] = (contactosPorTipo[tipo] || 0) + 1;
  });

  // --- Deals ---
  const totalDeals = deals.length;
  var valorTotal   = 0;
  var valorAbierto = 0;
  const dealsPorEtapa = {};

  deals.forEach(function(d) {
    var valor = parseFloat(d.valor) || 0;
    var etapa = d.etapa || 'sin-etapa';
    valorTotal += valor;
    dealsPorEtapa[etapa] = (dealsPorEtapa[etapa] || 0) + 1;

    // Valor de deals abiertos (no cerrados)
    if (etapa !== 'cerrado-ganado' && etapa !== 'cerrado-perdido') {
      valorAbierto += valor;
    }
  });

  // Pipeline ponderado (valor × probabilidad)
  var pipelinePonderado = 0;
  deals.forEach(function(d) {
    var valor = parseFloat(d.valor) || 0;
    var prob  = parseFloat(d.probabilidad) || 0;
    var etapa = d.etapa || '';
    if (etapa !== 'cerrado-ganado' && etapa !== 'cerrado-perdido') {
      pipelinePonderado += valor * (prob / 100);
    }
  });

  // Tasa de conversión
  var cerradosGanados  = dealsPorEtapa['cerrado-ganado']  || 0;
  var cerradosPerdidos = dealsPorEtapa['cerrado-perdido'] || 0;
  var totalCerrados    = cerradosGanados + cerradosPerdidos;
  var tasaConversion   = totalCerrados > 0 ? Math.round((cerradosGanados / totalCerrados) * 100) : 0;

  // --- Tareas ---
  const totalTareas = tareas.length;
  const tareasPorColumna = {};
  var tareasCompletadas = 0;

  tareas.forEach(function(t) {
    var col = t.columna || 'backlog';
    tareasPorColumna[col] = (tareasPorColumna[col] || 0) + 1;
    if (col === 'done' || t.completado) {
      tareasCompletadas++;
    }
  });

  // --- Reuniones ---
  const totalReuniones = reuniones.length;

  // Reuniones de los últimos 7 días
  var hace7Dias = new Date();
  hace7Dias.setDate(hace7Dias.getDate() - 7);
  var reunionesSemana = reuniones.filter(function(r) {
    return new Date(r.fecha) >= hace7Dias;
  }).length;

  // --- Actividad reciente (últimas 10) ---
  var actividadReciente = actividad.slice(-10).reverse();

  return {
    timestamp: new Date().toISOString(),
    contactos: {
      total: totalContactos,
      porTipo: contactosPorTipo
    },
    deals: {
      total: totalDeals,
      valorTotal: valorTotal,
      valorAbierto: valorAbierto,
      pipelinePonderado: Math.round(pipelinePonderado),
      porEtapa: dealsPorEtapa,
      tasaConversion: tasaConversion
    },
    tareas: {
      total: totalTareas,
      completadas: tareasCompletadas,
      porColumna: tareasPorColumna
    },
    reuniones: {
      total: totalReuniones,
      estaSemana: reunionesSemana
    },
    actividadReciente: actividadReciente
  };
}
