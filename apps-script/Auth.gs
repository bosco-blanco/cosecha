/**
 * ============================================================
 * Auth.gs - Autenticación passwordless por email corporativo
 * ============================================================
 * Flujo:
 *  1. Usuario introduce email → se valida el dominio corporativo
 *  2. Se genera un código de 6 dígitos y se envía por Gmail
 *  3. Usuario introduce código → se genera token de sesión
 *  4. Cliente guarda el token y lo envía en cada petición
 *  5. Sesión larga (30 días) o corta (24h) según preferencia
 *
 * Almacenamiento: pestaña "Auth" del Google Sheet.
 * ============================================================
 */

// ─── Configuración ──────────────────────────────────────────
const AUTH_DOMAIN_DEFAULT = 'encopadebalon.com';
const CODE_EXPIRY_MINUTES = 10;
const SESSION_LONG_DAYS   = 30;
const SESSION_SHORT_HOURS = 24;

// ─── API pública ────────────────────────────────────────────

/**
 * Solicita un código de acceso por email.
 * @param {string} email - Email corporativo.
 * @returns {Object} { success, message } o { success: false, error }
 */
function requestAuthCode(email) {
  email = String(email || '').toLowerCase().trim();

  // Validar formato básico
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { success: false, error: 'Email no válido' };
  }

  // Validar dominio corporativo
  const domain = getConfig_('AUTH_DOMAIN') || AUTH_DOMAIN_DEFAULT;
  if (!email.endsWith('@' + domain)) {
    return { success: false, error: 'Solo se permiten emails @' + domain };
  }

  // Generar código de 6 dígitos
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const now = new Date();
  const expires = new Date(now.getTime() + CODE_EXPIRY_MINUTES * 60000);

  // Limpiar códigos previos del mismo email
  clearAuthCodesForEmail_(email);

  // Guardar código
  const sheet = getOrCreateAuthSheet_();
  sheet.appendRow([
    Utilities.getUuid(),
    email,
    code,
    '',                     // token (vacío hasta que se verifique)
    now.toISOString(),
    expires.toISOString(),
    '',                     // lastUsed
    'code'                  // tipo
  ]);

  // Enviar email con el código
  try {
    sendAuthEmail_(email, code);
  } catch (err) {
    return { success: false, error: 'No se pudo enviar el email: ' + err.message };
  }

  return {
    success: true,
    message: 'Código enviado a ' + email,
    expiresInMinutes: CODE_EXPIRY_MINUTES
  };
}

/**
 * Verifica el código y crea una sesión.
 * @param {string} email
 * @param {string} code
 * @param {boolean} keepActive - Si true, sesión larga (30 días)
 * @returns {Object} { success, token, email, name, expiresAt }
 */
function verifyAuthCode(email, code, keepActive) {
  email = String(email || '').toLowerCase().trim();
  code  = String(code  || '').trim();

  const sheet = getOrCreateAuthSheet_();
  const data  = sheet.getDataRange().getValues();
  const now   = new Date();

  // Buscar código válido
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const type = row[7];
    const rEmail = row[1];
    const rCode  = row[2];
    const rExpires = new Date(row[5]);

    if (type === 'code' && rEmail === email && rCode === code) {
      if (rExpires > now) {
        // ✅ Código válido — generar sesión
        const token = Utilities.getUuid() + '-' + Utilities.getUuid();
        const ms = keepActive
          ? SESSION_LONG_DAYS * 24 * 60 * 60 * 1000
          : SESSION_SHORT_HOURS * 60 * 60 * 1000;
        const sessionExpires = new Date(now.getTime() + ms);

        // Guardar sesión
        sheet.appendRow([
          Utilities.getUuid(),
          email,
          '',
          token,
          now.toISOString(),
          sessionExpires.toISOString(),
          now.toISOString(),
          'session'
        ]);

        // Eliminar el código usado
        sheet.deleteRow(i + 1);

        // Registrar actividad
        try {
          logActivity_('🔑', emailToName_(email), 'inició sesión', 'Cosecha', '');
        } catch (e) {}

        return {
          success: true,
          token: token,
          email: email,
          name: emailToName_(email),
          expiresAt: sessionExpires.toISOString()
        };
      } else {
        return { success: false, error: 'Código expirado. Solicita uno nuevo.' };
      }
    }
  }

  return { success: false, error: 'Código incorrecto' };
}

/**
 * Valida un token de sesión existente.
 * @param {string} token
 * @returns {Object} { valid, email, name, expiresAt } o { valid: false }
 */
function validateAuthToken(token) {
  if (!token) return { valid: false };

  const sheet = getOrCreateAuthSheet_();
  const data  = sheet.getDataRange().getValues();
  const now   = new Date();

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (row[7] === 'session' && row[3] === token) {
      const expires = new Date(row[5]);
      if (expires > now) {
        // Actualizar lastUsed
        sheet.getRange(i + 1, 7).setValue(now.toISOString());
        return {
          valid: true,
          email: row[1],
          name: emailToName_(row[1]),
          expiresAt: expires.toISOString()
        };
      } else {
        // Sesión expirada → borrar
        sheet.deleteRow(i + 1);
        return { valid: false, error: 'Sesión expirada' };
      }
    }
  }

  return { valid: false };
}

/**
 * Cierra una sesión (logout).
 */
function logoutAuth(token) {
  if (!token) return { success: true };
  const sheet = getOrCreateAuthSheet_();
  const data  = sheet.getDataRange().getValues();
  for (let i = data.length - 1; i >= 1; i--) {
    if (data[i][7] === 'session' && data[i][3] === token) {
      sheet.deleteRow(i + 1);
    }
  }
  return { success: true };
}

/**
 * Limpia códigos y sesiones expirados (se puede llamar periódicamente).
 */
function cleanupAuth() {
  const sheet = getOrCreateAuthSheet_();
  const data  = sheet.getDataRange().getValues();
  const now   = new Date();
  let removed = 0;
  for (let i = data.length - 1; i >= 1; i--) {
    const expires = new Date(data[i][5]);
    if (expires < now) {
      sheet.deleteRow(i + 1);
      removed++;
    }
  }
  return { removed: removed };
}

// ─── Helpers internos ───────────────────────────────────────

/**
 * Crea la pestaña "Auth" si no existe.
 */
function getOrCreateAuthSheet_() {
  // Usamos el helper ya existente de Database.gs
  const ss = typeof getSpreadsheet_ === 'function'
    ? getSpreadsheet_()
    : SpreadsheetApp.openById(getSpreadsheetId_());
  let sheet = ss.getSheetByName('Auth');
  if (!sheet) {
    sheet = ss.insertSheet('Auth');
    const headers = ['id', 'email', 'code', 'token', 'created', 'expires', 'lastUsed', 'type'];
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight('bold')
      .setBackground('#9B2C3E')
      .setFontColor('#FFFFFF');
    sheet.setFrozenRows(1);
    sheet.setColumnWidths(1, headers.length, 150);
  }
  return sheet;
}

function clearAuthCodesForEmail_(email) {
  const sheet = getOrCreateAuthSheet_();
  const data  = sheet.getDataRange().getValues();
  for (let i = data.length - 1; i >= 1; i--) {
    if (data[i][7] === 'code' && data[i][1] === email) {
      sheet.deleteRow(i + 1);
    }
  }
}

/**
 * Envía el email con el código usando GmailApp (gratuito con Workspace).
 */
function sendAuthEmail_(email, code) {
  const subject = '🍇 Tu código para Cosecha: ' + code;

  const textBody = [
    'Hola,',
    '',
    'Tu código de acceso a Cosecha es:',
    '',
    '    ' + code,
    '',
    'Este código es válido durante ' + CODE_EXPIRY_MINUTES + ' minutos.',
    '',
    'Si no has solicitado este código, ignora este email.',
    '',
    '— Cosecha · En Copa de Balón'
  ].join('\n');

  const htmlBody = ''
    + '<div style="font-family:-apple-system,BlinkMacSystemFont,Inter,sans-serif;max-width:480px;margin:0 auto;padding:40px 20px;background:#FFFFFF;">'
    + '  <div style="text-align:center;margin-bottom:30px;">'
    + '    <div style="font-size:48px;line-height:1;">🍇</div>'
    + '    <h1 style="margin:12px 0 4px;color:#9B2C3E;font-size:26px;font-weight:800;letter-spacing:-0.5px;">Cosecha</h1>'
    + '    <p style="color:#999;font-size:11px;margin:0;letter-spacing:1.5px;font-weight:600;">EN COPA DE BALÓN</p>'
    + '  </div>'
    + '  <div style="background:#F7F7F8;border:1px solid #E5E5E7;border-radius:16px;padding:36px 24px;text-align:center;">'
    + '    <p style="color:#555;margin:0 0 22px;font-size:14px;">Tu código de acceso es:</p>'
    + '    <div style="font-size:44px;font-weight:800;letter-spacing:10px;color:#9B2C3E;font-family:ui-monospace,Menlo,monospace;padding:10px 0;">'
    + code
    + '    </div>'
    + '    <p style="color:#999;font-size:12px;margin:22px 0 0;">Válido durante ' + CODE_EXPIRY_MINUTES + ' minutos</p>'
    + '  </div>'
    + '  <p style="color:#AAA;font-size:11px;text-align:center;margin-top:24px;line-height:1.6;">Si no has solicitado este código, puedes ignorar este email sin problema.<br>Nadie podrá acceder a tu cuenta sin él.</p>'
    + '</div>';

  GmailApp.sendEmail(email, subject, textBody, {
    htmlBody: htmlBody,
    name: 'Cosecha'
  });
}

/**
 * Convierte "bosco.fernandez@encopadebalon.com" en "Bosco Fernández".
 */
function emailToName_(email) {
  const local = String(email || '').split('@')[0] || 'Usuario';
  return local
    .split(/[.\-_]/)
    .filter(Boolean)
    .map(p => p.charAt(0).toUpperCase() + p.slice(1))
    .join(' ');
}

/**
 * Obtiene el ID del spreadsheet desde PropertiesService (guardado por Database.gs).
 */
function getSpreadsheetId_() {
  const props = PropertiesService.getScriptProperties();
  let id = props.getProperty('SHEET_ID');
  if (id) return id;
  initSheet();
  return props.getProperty('SHEET_ID');
}
