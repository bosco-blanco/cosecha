/**
 * ============================================================
 * Cosecha CRM - Granola.gs
 * Integración con Granola (notas de reunión con IA).
 * Permite importar, parsear y vincular notas de Granola
 * con las reuniones del CRM.
 * ============================================================
 */

/**
 * Importa notas de Granola desde texto pegado por el usuario.
 * Granola exporta notas estructuradas con secciones claras.
 * @param {string} text - Texto completo de las notas de Granola.
 * @returns {Object} Datos estructurados extraídos de las notas.
 */
function importFromText(text) {
  if (!text || text.trim() === '') {
    return { error: true, message: 'El texto proporcionado está vacío.' };
  }

  var parsed = parseGranolaFormat(text);

  // Registrar actividad
  try {
    logActivity_('🎙️', 'Sistema', 'importó', 'notas Granola', parsed.titulo || 'Sin título');
  } catch (e) {
    // No interrumpir si falla el log
  }

  return parsed;
}

/**
 * Lee un archivo de exportación de Granola desde Google Drive.
 * Granola puede exportar a archivos .md o .txt en Drive.
 * @param {string} fileId - ID del archivo en Google Drive.
 * @returns {Object} Datos estructurados extraídos del archivo.
 */
function importFromDrive(fileId) {
  if (!fileId) {
    return { error: true, message: 'Se requiere un fileId para importar desde Drive.' };
  }

  try {
    var file    = DriveApp.getFileById(fileId);
    var content = file.getBlob().getDataAsString();
    var nombre  = file.getName();

    Logger.log('Importando notas de Granola desde Drive: ' + nombre);

    var parsed = parseGranolaFormat(content);

    // Si no se extrajo título, usar el nombre del archivo
    if (!parsed.titulo || parsed.titulo === 'Sin título') {
      // Eliminar extensión del nombre del archivo
      parsed.titulo = nombre.replace(/\.(md|txt|doc|docx)$/i, '').trim();
    }

    parsed.driveFileId   = fileId;
    parsed.driveFileName = nombre;

    return parsed;

  } catch (err) {
    Logger.log('Error al importar desde Drive: ' + err.message);
    return { error: true, message: 'No se pudo leer el archivo: ' + err.message };
  }
}

/**
 * Parsea el formato de exportación de Granola y extrae datos estructurados.
 * Granola típicamente organiza sus notas con secciones:
 *   - Título de la reunión
 *   - Fecha y hora
 *   - Asistentes
 *   - Summary / Resumen
 *   - Key Points / Puntos clave
 *   - Action Items / Acciones
 *   - Transcripción / Notas adicionales
 *
 * @param {string} content - Contenido crudo de las notas de Granola.
 * @returns {Object} Datos estructurados.
 */
function parseGranolaFormat(content) {
  if (!content) {
    return { error: true, message: 'Contenido vacío.' };
  }

  var result = {
    titulo:      '',
    fecha:       '',
    duracion:    '',
    asistentes:  [],
    resumen:     '',
    puntosClave: [],
    acciones:    [],
    palabras:    '',
    notasRaw:    content
  };

  // Normalizar saltos de línea
  var lines = content.replace(/\r\n/g, '\n').split('\n');

  // ─── Extraer título ───────────────────────────────────
  // El título suele ser la primera línea no vacía, posiblemente con # (Markdown)
  for (var i = 0; i < lines.length; i++) {
    var trimmed = lines[i].trim();
    if (trimmed !== '') {
      result.titulo = trimmed.replace(/^#+\s*/, ''); // Eliminar marcas Markdown
      break;
    }
  }

  // ─── Extraer fecha ────────────────────────────────────
  // Buscar patrones de fecha comunes
  var fechaPatterns = [
    /(?:Date|Fecha|Meeting date)[:\s]*(.+)/i,
    /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/,
    /(\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})/,
    /(\w+ \d{1,2},? \d{4})/
  ];

  for (var p = 0; p < fechaPatterns.length; p++) {
    var match = content.match(fechaPatterns[p]);
    if (match) {
      result.fecha = match[1] ? match[1].trim() : match[0].trim();
      break;
    }
  }

  // ─── Extraer asistentes ───────────────────────────────
  var asistentesSection = extractSection_(content, [
    'Attendees', 'Asistentes', 'Participants', 'Participantes', 'People', 'Personas'
  ]);
  if (asistentesSection) {
    result.asistentes = parseListItems_(asistentesSection);
  }

  // ─── Extraer resumen ──────────────────────────────────
  var resumenSection = extractSection_(content, [
    'Summary', 'Resumen', 'Overview', 'Descripción', 'Description', 'TL;DR'
  ]);
  if (resumenSection) {
    result.resumen = resumenSection.trim();
  }

  // ─── Extraer puntos clave ─────────────────────────────
  var puntosSection = extractSection_(content, [
    'Key Points', 'Key Takeaways', 'Puntos clave', 'Puntos principales',
    'Highlights', 'Takeaways', 'Main Points', 'Conclusiones'
  ]);
  if (puntosSection) {
    result.puntosClave = parseListItems_(puntosSection);
  }

  // ─── Extraer acciones ─────────────────────────────────
  var accionesSection = extractSection_(content, [
    'Action Items', 'Actions', 'Acciones', 'Tareas', 'Tasks',
    'Next Steps', 'Próximos pasos', 'To Do', 'To-Do', 'Follow-up', 'Seguimiento'
  ]);
  if (accionesSection) {
    result.acciones = parseListItems_(accionesSection);
  }

  // ─── Extraer duración ─────────────────────────────────
  var duracionMatch = content.match(/(?:Duration|Duración|Length)[:\s]*(\d+)\s*(?:min|minutes|minutos)/i);
  if (duracionMatch) {
    result.duracion = duracionMatch[1];
  }

  // ─── Contar palabras (de la transcripción si existe) ──
  var transcripcion = extractSection_(content, [
    'Transcript', 'Transcripción', 'Notes', 'Notas', 'Discussion', 'Conversación'
  ]);
  if (transcripcion) {
    result.palabras = String(transcripcion.split(/\s+/).length);
  } else {
    result.palabras = String(content.split(/\s+/).length);
  }

  return result;
}

/**
 * Vincula datos parseados de Granola a una reunión existente en el CRM.
 * Actualiza la reunión con el resumen, puntos clave y acciones extraídos.
 * @param {string} meetingId - ID de la reunión en el CRM.
 * @param {Object} granolaData - Datos parseados de Granola.
 * @returns {Object} Reunión actualizada.
 */
function linkToMeeting(meetingId, granolaData) {
  if (!meetingId) {
    return { error: true, message: 'Se requiere un meetingId para vincular las notas.' };
  }

  // Obtener la reunión existente
  var reunion = getById('Reuniones', meetingId);
  if (!reunion) {
    return { error: true, message: 'Reunión no encontrada con ID: ' + meetingId };
  }

  // Preparar los datos de actualización
  var actualizacion = {
    id: meetingId
  };

  // Solo actualizar campos que tengan contenido nuevo
  if (granolaData.resumen) {
    actualizacion.resumen = granolaData.resumen;
  }

  if (granolaData.puntosClave && granolaData.puntosClave.length > 0) {
    actualizacion.puntosClave = JSON.stringify(granolaData.puntosClave);
  }

  if (granolaData.acciones && granolaData.acciones.length > 0) {
    actualizacion.acciones = JSON.stringify(granolaData.acciones);
  }

  if (granolaData.palabras) {
    actualizacion.palabras = granolaData.palabras;
  }

  if (granolaData.asistentes && granolaData.asistentes.length > 0) {
    actualizacion.asistentes = JSON.stringify(granolaData.asistentes);
  }

  // Guardar las notas completas de Granola como referencia
  actualizacion.notasGranola = JSON.stringify({
    importado: new Date().toISOString(),
    titulo: granolaData.titulo,
    driveFileId: granolaData.driveFileId || null,
    notasRaw: granolaData.notasRaw || ''
  });

  // Actualizar la reunión
  var resultado = upsert('Reuniones', actualizacion);

  // Registrar actividad
  logActivity_('🎙️', 'Sistema', 'vinculó notas Granola a', 'reunión', reunion.titulo || meetingId);

  // Si hay acciones, opcionalmente crear tareas
  if (granolaData.acciones && granolaData.acciones.length > 0) {
    resultado.tareasCreadas = granolaData.acciones.length;
    resultado.acciones = granolaData.acciones;
  }

  return resultado;
}

/**
 * Busca archivos recientes de exportación de Granola en Google Drive.
 * Busca archivos con nombres que contengan "Granola", "Meeting Notes",
 * "Notas de reunión" o similares, creados en los últimos 30 días.
 * @returns {Object[]} Lista de archivos encontrados con id, nombre y fecha.
 */
function searchDriveForGranola() {
  var resultados = [];

  // Buscar archivos con diferentes patrones de nombre
  var busquedas = [
    'title contains "Granola"',
    'title contains "Meeting Notes"',
    'title contains "Notas de reunión"',
    'title contains "meeting-notes"'
  ];

  // Fecha límite: últimos 30 días
  var hace30Dias = new Date();
  hace30Dias.setDate(hace30Dias.getDate() - 30);
  var fechaLimite = Utilities.formatDate(hace30Dias, 'Europe/Madrid', "yyyy-MM-dd'T'HH:mm:ss");

  var idsVistos = {};

  busquedas.forEach(function(query) {
    try {
      var fullQuery = query + ' and modifiedDate > "' + fechaLimite + '" and trashed = false';
      var files = DriveApp.searchFiles(fullQuery);

      while (files.hasNext()) {
        var file = files.next();
        var id   = file.getId();

        // Evitar duplicados
        if (idsVistos[id]) continue;
        idsVistos[id] = true;

        resultados.push({
          id:           id,
          nombre:       file.getName(),
          mimeType:     file.getMimeType(),
          fechaCreado:  file.getDateCreated().toISOString(),
          fechaModif:   file.getLastUpdated().toISOString(),
          url:          file.getUrl(),
          tamano:       file.getSize()
        });
      }
    } catch (err) {
      Logger.log('Error en búsqueda de Drive (' + query + '): ' + err.message);
    }
  });

  // Ordenar por fecha de modificación (más reciente primero)
  resultados.sort(function(a, b) {
    return new Date(b.fechaModif) - new Date(a.fechaModif);
  });

  Logger.log('Archivos de Granola encontrados: ' + resultados.length);

  return {
    total:     resultados.length,
    archivos:  resultados
  };
}

// ─── Helpers internos ───────────────────────────────────────

/**
 * Extrae una sección del contenido basándose en posibles encabezados.
 * Busca desde el encabezado hasta el siguiente encabezado de igual o mayor nivel.
 * @param {string} content - Contenido completo.
 * @param {string[]} headerNames - Posibles nombres del encabezado de la sección.
 * @returns {string|null} Contenido de la sección o null si no se encuentra.
 */
function extractSection_(content, headerNames) {
  for (var h = 0; h < headerNames.length; h++) {
    var headerName = headerNames[h];

    // Buscar el encabezado con diferentes formatos:
    // - ## Header Name
    // - **Header Name**
    // - Header Name:
    // - Header Name
    var patterns = [
      new RegExp('#{1,3}\\s*' + escapeRegex_(headerName) + '\\s*\\n', 'i'),
      new RegExp('\\*\\*\\s*' + escapeRegex_(headerName) + '\\s*\\*\\*\\s*:?\\s*\\n', 'i'),
      new RegExp('^' + escapeRegex_(headerName) + '\\s*:\\s*\\n', 'im'),
      new RegExp('^' + escapeRegex_(headerName) + '\\s*\\n', 'im')
    ];

    for (var p = 0; p < patterns.length; p++) {
      var match = content.match(patterns[p]);
      if (match) {
        var startIdx = match.index + match[0].length;
        var rest     = content.substring(startIdx);

        // Encontrar el final de la sección (siguiente encabezado o fin del contenido)
        var endMatch = rest.match(/\n(?:#{1,3}\s|\*\*[A-Z])/);
        var sectionContent = endMatch ? rest.substring(0, endMatch.index) : rest;

        var trimmed = sectionContent.trim();
        if (trimmed !== '') {
          return trimmed;
        }
      }
    }
  }

  return null;
}

/**
 * Parsea elementos de lista de un bloque de texto.
 * Reconoce formatos: "- item", "* item", "• item", "1. item", "1) item", "☑️ item", "[] item"
 * @param {string} text - Texto con elementos de lista.
 * @returns {string[]} Array de elementos de lista limpios.
 */
function parseListItems_(text) {
  var lines = text.split('\n');
  var items = [];

  lines.forEach(function(line) {
    var trimmed = line.trim();
    if (trimmed === '') return;

    // Eliminar marcadores de lista comunes
    var cleaned = trimmed
      .replace(/^[-*•]\s+/, '')          // - item, * item, • item
      .replace(/^\d+[.)]\s+/, '')        // 1. item, 1) item
      .replace(/^☑️\s*/, '')             // ☑️ item
      .replace(/^\[[ x]?\]\s*/i, '')     // [] item, [x] item
      .replace(/^>\s+/, '')              // > item (blockquote)
      .trim();

    if (cleaned !== '' && cleaned.length > 1) {
      items.push(cleaned);
    }
  });

  return items;
}

/**
 * Escapa caracteres especiales de regex en un string.
 * @param {string} str - String a escapar.
 * @returns {string} String con caracteres especiales escapados.
 */
function escapeRegex_(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
