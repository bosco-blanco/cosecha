/**
 * ============================================================
 * Legal.gs - Consentimiento legal y RGPD/LOPD
 * ============================================================
 * Cumplimiento normativo obligatorio para una app laboral en España:
 *  - RGPD (Reglamento General de Protección de Datos)
 *  - LOPD-GDD (Ley Orgánica 3/2018 de Protección de Datos)
 *  - Real Decreto-ley 8/2019 (registro de jornada laboral)
 *  - Directiva 2019/1937 (canal de denuncias)
 *
 * Cada vez que un usuario inicia sesión por primera vez (o cuando
 * se publica una nueva versión de la política), debe aceptar
 * explícitamente los consentimientos.
 *
 * La evidencia se guarda en la pestaña "Consentimientos" con:
 *  - email del usuario
 *  - versión de la política aceptada
 *  - fecha/hora exacta de aceptación
 *  - items aceptados (JSON)
 *  - user agent del dispositivo
 * ============================================================
 */

// ─── Versión actual de la política ──────────────────────────
// Incrementar esto cuando se cambien los textos legales →
// obligará a todos los usuarios a re-aceptar.
const LEGAL_VERSION = '1.0.0';

// ─── API pública ────────────────────────────────────────────

/**
 * Comprueba si un usuario ya ha aceptado la versión actual de la política.
 * @param {string} email
 * @returns {Object} { accepted, version, acceptedAt }
 */
function getConsentStatus(email) {
  email = String(email || '').toLowerCase().trim();
  if (!email) return { accepted: false };

  const sheet = getOrCreateConsentSheet_();
  const data = sheet.getDataRange().getValues();

  // Buscar la aceptación más reciente de este usuario para la versión actual
  for (let i = data.length - 1; i >= 1; i--) {
    if (String(data[i][1]).toLowerCase() === email && data[i][2] === LEGAL_VERSION) {
      return {
        accepted: true,
        version: data[i][2],
        acceptedAt: data[i][3],
        currentVersion: LEGAL_VERSION
      };
    }
  }

  return {
    accepted: false,
    currentVersion: LEGAL_VERSION
  };
}

/**
 * Guarda la aceptación del consentimiento.
 * @param {Object} body { email, version, items: {dataProcessing, geolocation, audio, documents}, userAgent }
 */
function saveConsent(body) {
  const email = String(body.email || '').toLowerCase().trim();
  if (!email) return { success: false, error: 'Email requerido' };

  const version = body.version || LEGAL_VERSION;
  const items = body.items || {};

  // Validar: los obligatorios deben estar aceptados
  const required = ['dataProcessing', 'workdayTracking'];
  for (let i = 0; i < required.length; i++) {
    if (!items[required[i]]) {
      return { success: false, error: 'Debes aceptar: ' + required[i] };
    }
  }

  const sheet = getOrCreateConsentSheet_();
  sheet.appendRow([
    Utilities.getUuid(),
    email,
    version,
    new Date().toISOString(),
    JSON.stringify(items),
    body.userAgent || '',
    body.ip || ''
  ]);

  // Registrar en actividad
  try {
    logActivity_('⚖️', emailToName_(email), 'aceptó', 'política de privacidad v' + version, '');
  } catch (e) {}

  return { success: true, version: version };
}

/**
 * Devuelve el texto legal actual (para que el frontend lo muestre).
 * Así centralizamos los textos en el backend y se pueden cambiar
 * sin tocar el código del cliente.
 */
function getLegalText() {
  return {
    version: LEGAL_VERSION,
    lastUpdated: '2026-04-11',
    company: 'En Copa de Balón S.L.',
    sections: [
      {
        id: 'dataProcessing',
        required: true,
        title: '📋 Tratamiento de datos personales',
        body: 'En cumplimiento del Reglamento (UE) 2016/679 (RGPD) y la Ley Orgánica 3/2018 (LOPD-GDD), te informamos de que En Copa de Balón S.L. trata tus datos personales (nombre, email corporativo, rol, departamento) con la finalidad de gestionar la relación laboral, organizar el trabajo del equipo y cumplir con las obligaciones legales. La base legal es la ejecución del contrato de trabajo (art. 6.1.b RGPD). Puedes ejercer tus derechos de acceso, rectificación, supresión, oposición, limitación y portabilidad escribiendo a rrhh@encopadebalon.com.'
      },
      {
        id: 'workdayTracking',
        required: true,
        title: '⏱️ Registro de jornada laboral',
        body: 'De acuerdo con el Real Decreto-ley 8/2019 que modifica el Estatuto de los Trabajadores, la empresa está obligada a llevar un registro diario de la jornada de cada empleado. Cosecha registra la hora de entrada, la de salida y los descansos. Estos datos se conservan durante 4 años y están disponibles para la Inspección de Trabajo. Este registro es obligatorio y no requiere consentimiento adicional por tu parte más allá de tu conocimiento.'
      },
      {
        id: 'geolocation',
        required: false,
        title: '📍 Geolocalización (voluntaria)',
        body: 'Puedes activar la geolocalización al fichar entrada/salida o al registrar reuniones con clientes. Si lo haces, guardaremos las coordenadas GPS junto con el fichaje o la reunión, con la finalidad de verificar presencia en el centro de trabajo o documentar visitas comerciales. Esta funcionalidad es opcional y puedes rechazarla en cualquier momento desde los ajustes de tu navegador. Los datos de ubicación se borran automáticamente a los 12 meses.'
      },
      {
        id: 'audio',
        required: false,
        title: '🎙️ Grabación y transcripción de reuniones (voluntaria)',
        body: 'Cosecha permite grabar y transcribir reuniones usando el micrófono de tu dispositivo. Si usas esta función, eres responsable de informar y obtener el consentimiento de todos los participantes antes de iniciar la grabación. La transcripción se almacena en Google Drive de la empresa. Puedes no usar esta función sin ninguna penalización.'
      },
      {
        id: 'documents',
        required: false,
        title: '📁 Gestión documental',
        body: 'Cosecha permite al departamento de RRHH enviarte documentación laboral (nóminas, contratos, comunicados) para su lectura y firma electrónica. Tu firma electrónica dentro de la app equivale, según el artículo 10 de la Ley 6/2020 sobre servicios electrónicos de confianza, a una firma electrónica simple y tiene validez contractual entre tú y la empresa.'
      }
    ],
    contact: {
      company: 'En Copa de Balón S.L.',
      dpo: 'rrhh@encopadebalon.com',
      address: 'Madrid, España'
    }
  };
}

// ─── Helpers internos ───────────────────────────────────────

function getOrCreateConsentSheet_() {
  const ss = getSpreadsheet_() || initSheet();
  let sheet = ss.getSheetByName('Consentimientos');
  if (!sheet) {
    sheet = ss.insertSheet('Consentimientos');
    const headers = ['id', 'email', 'version', 'aceptadoEn', 'items', 'userAgent', 'ip'];
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight('bold')
      .setBackground('#722F37')
      .setFontColor('#FFFFFF');
    sheet.setFrozenRows(1);
    sheet.setColumnWidths(1, headers.length, 180);
  }
  return sheet;
}
