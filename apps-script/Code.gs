/**
 * ============================================================
 * Cosecha CRM - Backend Google Apps Script
 * Para "En Copa de Balón" (grupo hostelero, España)
 * ============================================================
 * Archivo principal: enrutador API REST (doGet / doPost).
 * Se despliega como Web App en script.google.com.
 * Coste: 0 € — usa Google Sheets como base de datos.
 * ============================================================
 */

// ─── Constantes globales ────────────────────────────────────
const ALLOWED_ORIGINS = '*'; // En producción, restringir al dominio de la PWA

// Rutas que NO requieren autenticación
const PUBLIC_ACTIONS = ['requestCode', 'verifyCode', 'validateToken', 'legalText', ''];

// ─── Punto de entrada GET ───────────────────────────────────
function doGet(e) {
  try {
    // Asegurar que la hoja existe antes de cualquier operación
    initSheet();

    const action = (e.parameter && e.parameter.action) || '';

    // --- Auth: rutas públicas (aceptan GET para evitar CORS POST issues) ---
    if (action === 'validateToken') {
      const token = e.parameter.token || '';
      return buildResponse_(validateAuthToken(token));
    }
    if (action === 'requestCode') {
      return buildResponse_(requestAuthCode(e.parameter.email));
    }
    if (action === 'verifyCode') {
      return buildResponse_(verifyAuthCode(e.parameter.email, e.parameter.code, e.parameter.keepActive === 'true'));
    }
    if (action === 'legalText') {
      return buildResponse_(getLegalText());
    }

    // --- Rutas protegidas: validar token ---
    let auth = { valid: true, email: '', name: '', rol: '' };
    if (PUBLIC_ACTIONS.indexOf(action) === -1) {
      const token = e.parameter.token || '';
      auth = validateAuthToken(token);
      if (!auth.valid) {
        return buildResponse_({ error: true, code: 'UNAUTHORIZED', message: 'Sesión inválida o expirada' });
      }
    }

    let result;

    switch (action) {
      case 'contacts':
        result = getAll('Contactos');
        break;

      case 'deals':
        result = getAll('Deals');
        break;

      case 'tasks':
        result = getAll('Tareas');
        break;

      case 'meetings':
        result = getAll('Reuniones');
        break;

      case 'dashboard':
        result = getDashboardStats();
        break;

      case 'calendar': {
        const start = e.parameter.start || null;
        const end   = e.parameter.end   || null;
        const days  = e.parameter.days  ? parseInt(e.parameter.days, 10) : 30;
        result = start && end
          ? listEvents(new Date(start), new Date(end))
          : getUpcomingEvents(days);
        break;
      }

      case 'users':
        result = listUsers();
        break;

      case 'checkinStatus':
        result = getCheckinStatus(auth.email);
        break;

      case 'checkinHistory':
        result = getCheckinHistory(auth.email, e.parameter.days || 30);
        break;

      case 'checkinsToday':
        // Solo admin puede ver fichajes de todos
        if (auth.rol !== 'admin') {
          result = { error: true, message: 'Solo admin' };
        } else {
          result = getAllCheckinsToday();
        }
        break;

      case 'me':
        // Perfil del usuario autenticado
        result = {
          email: auth.email,
          name: auth.name,
          rol: auth.rol,
          color: auth.color,
          avatar: auth.avatar
        };
        break;

      case 'legalText':
        // Devuelve los textos legales actuales (pública, sin auth)
        result = getLegalText();
        break;

      case 'consentStatus':
        result = getConsentStatus(auth.email);
        break;

      case 'myDocuments':
        result = getUserDocuments(auth.email);
        break;

      case 'allDocuments':
        if (auth.rol !== 'admin') { result = { error: true, message: 'Solo admin' }; break; }
        result = getAllDocuments();
        break;

      default:
        result = {
          app: 'Cosecha CRM',
          version: '1.1.0',
          status: 'ok',
          message: 'Backend activo. Endpoints GET: contacts|deals|tasks|meetings|dashboard|calendar|validateToken. Todos requieren ?token=... excepto validateToken.'
        };
    }

    return buildResponse_(result);

  } catch (err) {
    return buildResponse_({ error: true, message: err.message, stack: err.stack }, 500);
  }
}

// ─── Punto de entrada POST ──────────────────────────────────
function doPost(e) {
  try {
    initSheet();

    const action = (e.parameter && e.parameter.action) || '';
    const body   = e.postData ? JSON.parse(e.postData.contents) : {};
    let result;

    // --- Auth: rutas públicas ---
    if (action === 'requestCode') {
      return buildResponse_(requestAuthCode(body.email));
    }
    if (action === 'verifyCode') {
      return buildResponse_(verifyAuthCode(body.email, body.code, !!body.keepActive));
    }
    if (action === 'logout') {
      return buildResponse_(logoutAuth(body.token));
    }
    if (action === 'saveConsent') {
      return buildResponse_(saveConsent(body));
    }

    // --- Rutas protegidas ---
    const token = (body && body.token) || (e.parameter && e.parameter.token) || '';
    const auth = validateAuthToken(token);
    if (!auth.valid) {
      return buildResponse_({ error: true, code: 'UNAUTHORIZED', message: 'Sesión inválida o expirada' });
    }
    // Inyectar el email del usuario autenticado como "quien" en actividades
    const whoami = auth.name || auth.email || 'Sistema';

    switch (action) {
      // --- CRUD individual ---
      case 'contact':
        if (!body.creadoPor) body.creadoPor = auth.email;
        result = upsert('Contactos', body);
        logActivity_('👤', whoami, body.id ? 'actualizó' : 'creó', 'contacto', body.nombre || '');
        break;

      case 'deal':
        result = upsert('Deals', body);
        logActivity_('💰', whoami, body.id ? 'actualizó' : 'creó', 'deal', body.titulo || '');
        break;

      case 'task':
        result = upsert('Tareas', body);
        logActivity_('🍇', whoami, body.id ? 'actualizó' : 'creó', 'tarea', body.titulo || '');
        break;

      case 'meeting':
        result = upsert('Reuniones', body);
        logActivity_('🎙️', whoami, body.id ? 'actualizó' : 'registró', 'reunión', body.titulo || '');
        break;

      case 'checkin':
        // Forzar el email del usuario autenticado (no se puede fichar por otro)
        body.email = auth.email;
        result = registerCheckin(body);
        break;

      case 'startBreak':
        body.email = auth.email;
        result = startBreak(body);
        break;

      case 'endBreak':
        body.email = auth.email;
        result = endBreak(body);
        break;

      // --- Documentos ---
      case 'sendDocument':
        if (auth.rol !== 'admin') { result = { error: true, message: 'Solo admin' }; break; }
        body.enviadoPor = auth.email;
        result = sendDocument(body);
        break;

      case 'markDocRead':
        body.email = auth.email;
        result = markDocumentRead(body);
        break;

      case 'signDocument':
        body.email = auth.email;
        result = signDocument(body);
        break;

      // --- Admin: gestión de usuarios ---
      case 'inviteUser':
        if (auth.rol !== 'admin') { result = { error: true, message: 'Solo admin' }; break; }
        result = inviteUser(body);
        break;

      case 'updateUser':
        if (auth.rol !== 'admin') { result = { error: true, message: 'Solo admin' }; break; }
        result = updateUser(body);
        break;

      case 'deleteUser':
        if (auth.rol !== 'admin') { result = { error: true, message: 'Solo admin' }; break; }
        result = deleteUser(body.email);
        break;

      // --- Sincronización completa (offline-first) ---
      case 'sync':
        result = handleSync_(body);
        break;

      // --- Slack ---
      case 'slack': {
        const webhookUrl = body.webhookUrl || getConfig_('SLACK_WEBHOOK_URL');
        const channel    = body.channel    || getConfig_('SLACK_CHANNEL') || '#cosecha-crm';
        if (body.type && body.data) {
          // Notificación formateada
          const msg = formatSlackMessage(body.type, body.data);
          result = sendSlack(webhookUrl, channel, msg.text, msg.blocks);
        } else {
          // Mensaje libre
          result = sendSlack(webhookUrl, channel, body.message || '', body.blocks || null);
        }
        break;
      }

      // --- Google Calendar ---
      case 'calendarEvent': {
        if (body.meetingId) {
          result = syncMeetingToCalendar(body);
        } else {
          result = createEvent(
            body.title,
            new Date(body.start),
            new Date(body.end),
            body.attendees || [],
            body.description || '',
            body.location || ''
          );
        }
        break;
      }

      // --- Granola (notas de reunión) ---
      case 'granola': {
        if (body.text) {
          result = importFromText(body.text);
        } else if (body.fileId) {
          result = importFromDrive(body.fileId);
        } else if (body.search) {
          result = searchDriveForGranola();
        }
        if (body.meetingId && result) {
          result = linkToMeeting(body.meetingId, result);
        }
        break;
      }

      // --- Eliminar registros ---
      case 'delete': {
        const tab = body.tab || '';
        const id  = body.id  || '';
        if (tab && id) {
          result = deleteRow(tab, id);
          logActivity_('🗑️', 'Sistema', 'eliminó', tab, id);
        } else {
          result = { error: true, message: 'Se requiere tab e id para eliminar' };
        }
        break;
      }

      default:
        result = { error: true, message: 'Acción POST no reconocida: ' + action };
    }

    return buildResponse_(result);

  } catch (err) {
    return buildResponse_({ error: true, message: err.message, stack: err.stack }, 500);
  }
}

// ─── Helpers ────────────────────────────────────────────────

/**
 * Construye una respuesta JSON con cabeceras CORS.
 * @param {Object} data - Datos a serializar.
 * @param {number} [status=200] - Código de estado HTTP (informativo; Apps Script siempre devuelve 200).
 * @returns {TextOutput}
 */
function buildResponse_(data, status) {
  const output = ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
  return output;
}

/**
 * Registra una actividad en la pestaña "Actividad".
 */
function logActivity_(icono, quien, accion, que, detalle) {
  try {
    const row = {
      id: Utilities.getUuid(),
      icono: icono,
      quien: quien,
      accion: accion,
      que: que,
      detalle: detalle,
      timestamp: new Date().toISOString()
    };
    upsert('Actividad', row);
  } catch (err) {
    // No interrumpir la operación principal si falla el log
    Logger.log('Error al registrar actividad: ' + err.message);
  }
}

/**
 * Obtiene un valor de la pestaña Config.
 */
function getConfig_(clave) {
  try {
    const datos = getAll('Config');
    const fila  = datos.find(function(r) { return r.clave === clave; });
    return fila ? fila.valor : '';
  } catch (err) {
    return '';
  }
}

/**
 * Gestiona la sincronización completa desde el cliente offline-first.
 * Recibe todas las entidades modificadas y devuelve el estado actual del servidor.
 */
function handleSync_(body) {
  const resultado = { sincronizado: true, timestamp: new Date().toISOString() };

  // Procesar cada tipo de entidad si viene en el body
  const entidades = {
    contactos: 'Contactos',
    deals:     'Deals',
    tareas:    'Tareas',
    reuniones: 'Reuniones'
  };

  Object.keys(entidades).forEach(function(clave) {
    const tab = entidades[clave];
    if (body[clave] && Array.isArray(body[clave])) {
      body[clave].forEach(function(item) {
        upsert(tab, item);
      });
    }
    // Devolver datos actuales del servidor
    resultado[clave] = getAll(tab);
  });

  // Incluir actividad reciente (últimas 50 entradas)
  const actividad = getAll('Actividad');
  resultado.actividad = actividad.slice(-50);

  return resultado;
}
