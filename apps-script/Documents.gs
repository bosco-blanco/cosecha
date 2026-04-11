/**
 * ============================================================
 * Documents.gs - Gestión documental de empleados
 * ============================================================
 * RRHH (rol admin) puede enviar documentos a empleados (nóminas,
 * contratos, comunicados, etc.) para que los lean y firmen
 * electrónicamente dentro de la app.
 *
 * Cada documento tiene un estado:
 *  - pendiente: enviado, aún no abierto
 *  - leido:     el empleado lo ha abierto
 *  - firmado:   el empleado ha firmado electrónicamente
 *
 * Los archivos físicos se guardan en Google Drive (en una carpeta
 * "Cosecha / Documentos / {email}" por empleado) y solo guardamos
 * el driveFileId en Sheets.
 * ============================================================
 */

// ─── Admin: subir archivo directamente a Drive ──────────────

/**
 * Sube un archivo a Google Drive en la carpeta del empleado y
 * registra el documento en la pestaña Documentos.
 *
 * @param {Object} body {
 *   userEmail, titulo, tipo, fileName, base64, mimeType, nota, enviadoPor
 * }
 */
function uploadDocToDrive(body) {
  const userEmail = String(body.userEmail || '').toLowerCase().trim();
  const titulo    = String(body.titulo || '').trim();
  if (!userEmail) return { success: false, error: 'Destinatario requerido' };
  if (!titulo)    return { success: false, error: 'Título requerido' };
  if (!body.base64) return { success: false, error: 'Archivo vacío' };

  // Crear blob del archivo
  let blob;
  try {
    blob = Utilities.newBlob(
      Utilities.base64Decode(body.base64),
      body.mimeType || 'application/octet-stream',
      body.fileName || 'documento'
    );
  } catch (e) {
    return { success: false, error: 'Error decodificando el archivo: ' + e.message };
  }

  // Estructura de carpetas: "Cosecha" > "Documentos" > "{email}"
  const rootFolder = getOrCreateFolder_(DriveApp, 'Cosecha');
  const docsFolder = getOrCreateFolderInside_(rootFolder, 'Documentos');
  const userFolder = getOrCreateFolderInside_(docsFolder, userEmail);

  const file = userFolder.createFile(blob);
  if (body.nota) file.setDescription(body.nota);

  // Registrar metadata en pestaña Documentos
  return sendDocument({
    userEmail: userEmail,
    titulo: titulo,
    tipo: body.tipo || 'comunicado',
    driveFileId: file.getId(),
    driveUrl: file.getUrl(),
    nota: body.nota || '',
    enviadoPor: body.enviadoPor || ''
  });
}

function getOrCreateFolder_(driveOrFolder, name) {
  const folders = driveOrFolder.getFoldersByName(name);
  if (folders.hasNext()) return folders.next();
  return driveOrFolder.createFolder(name);
}

function getOrCreateFolderInside_(parent, name) {
  const folders = parent.getFoldersByName(name);
  if (folders.hasNext()) return folders.next();
  return parent.createFolder(name);
}

// ─── Admin: enviar documento ────────────────────────────────

/**
 * Registra un documento enviado a un empleado.
 * @param {Object} body { userEmail, titulo, tipo, driveFileId, driveUrl, nota }
 */
function sendDocument(body) {
  const userEmail = String(body.userEmail || '').toLowerCase().trim();
  const titulo = String(body.titulo || '').trim();
  if (!userEmail) return { success: false, error: 'Destinatario requerido' };
  if (!titulo) return { success: false, error: 'Título requerido' };

  const doc = {
    id: Utilities.getUuid(),
    email: userEmail,
    titulo: titulo,
    tipo: body.tipo || 'comunicado',   // nomina | contrato | comunicado | politica | otro
    driveFileId: body.driveFileId || '',
    driveUrl: body.driveUrl || '',
    estado: 'pendiente',
    enviadoPor: body.enviadoPor || '',
    enviadoEn: new Date().toISOString(),
    firmadoEn: '',
    nota: body.nota || ''
  };
  upsert('Documentos', doc);

  try {
    logActivity_('📄', body.enviadoPor || 'RRHH', 'envió documento', titulo, userEmail);
  } catch (e) {}

  // Notificar al empleado por email
  try {
    notifyDocumentEmail_(userEmail, titulo, body.tipo);
  } catch (e) {}

  return { success: true, documento: doc };
}

/**
 * Lista todos los documentos de un usuario.
 */
function getUserDocuments(email) {
  email = String(email || '').toLowerCase().trim();
  const all = getAll('Documentos');
  return all
    .filter(d => String(d.email).toLowerCase() === email)
    .sort((a, b) => new Date(b.enviadoEn) - new Date(a.enviadoEn));
}

/**
 * Lista todos los documentos (solo admin).
 */
function getAllDocuments() {
  return getAll('Documentos');
}

/**
 * Marca un documento como leído por el usuario.
 */
function markDocumentRead(body) {
  const id = body.id;
  const email = String(body.email || '').toLowerCase().trim();
  if (!id) return { success: false, error: 'ID requerido' };

  const sheet = getTabSheet_('Documentos');
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id && String(data[i][1]).toLowerCase() === email) {
      if (data[i][6] === 'pendiente') {
        sheet.getRange(i + 1, 7).setValue('leido');
      }
      return { success: true };
    }
  }
  return { success: false, error: 'No encontrado' };
}

/**
 * Firma electrónicamente un documento con evidencia legal completa.
 * Cumple con el artículo 10 de la Ley 6/2020 sobre servicios electrónicos de
 * confianza (firma electrónica simple):
 *  - Identificación del firmante: email autenticado por magic link + token
 *  - Manifestación del consentimiento: nombre completo escrito por el usuario
 *  - Vinculación con el documento: ID del documento
 *  - Evidencia técnica: IP pública, geolocalización, user agent, timestamp
 *  - Registro inalterable: huella SHA-256 del conjunto
 *
 * @param {Object} body {
 *   id, email, firmaNombre, firmaIp, firmaLat, firmaLng, firmaDireccion,
 *   firmaUserAgent, leido, consentimiento
 * }
 */
function signDocument(body) {
  const id = body.id;
  const email = String(body.email || '').toLowerCase().trim();
  if (!id) return { success: false, error: 'ID del documento requerido' };

  // Validación: el usuario debe confirmar explícitamente que ha leído y consiente
  if (!body.leido)          return { success: false, error: 'Debes confirmar que has leído el documento' };
  if (!body.consentimiento) return { success: false, error: 'Debes consentir electrónicamente la firma' };

  // Validación: nombre completo obligatorio y debe parecerse al registrado
  const firmaNombre = String(body.firmaNombre || '').trim();
  if (firmaNombre.length < 4) {
    return { success: false, error: 'Escribe tu nombre completo' };
  }
  let user = null;
  try { user = getOrCreateUser_(email); } catch (e) {}
  const expected = (user && user.nombre) ? String(user.nombre).trim().toLowerCase() : emailToName_(email).toLowerCase();
  const typed = firmaNombre.toLowerCase();
  // Coincidencia flexible: debe compartir al menos las primeras palabras
  const expectedTokens = expected.split(/\s+/).filter(Boolean);
  const typedTokens = typed.split(/\s+/).filter(Boolean);
  const matchCount = expectedTokens.filter(t => typedTokens.includes(t)).length;
  if (matchCount < Math.min(2, expectedTokens.length)) {
    return { success: false, error: 'El nombre no coincide con tu perfil (' + (user && user.nombre) + ')' };
  }

  const sheet = getTabSheet_('Documentos');
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id && String(data[i][1]).toLowerCase() === email) {
      const now = new Date();
      const nowIso = now.toISOString();

      // Generar huella SHA-256 para verificación posterior
      const toHash = [id, email, firmaNombre, nowIso, body.firmaIp || '', body.firmaLat || '', body.firmaLng || ''].join('|');
      const hashBytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, toHash);
      const hashHex = hashBytes.map(function(b) { return ('0' + (b & 0xff).toString(16)).slice(-2); }).join('');

      // Guardar estado y evidencia
      sheet.getRange(i + 1, 7 ).setValue('firmado');             // estado
      sheet.getRange(i + 1, 10).setValue(nowIso);                 // firmadoEn
      sheet.getRange(i + 1, 12).setValue(firmaNombre);            // firmaNombre
      sheet.getRange(i + 1, 13).setValue(body.firmaIp || '');     // firmaIp
      sheet.getRange(i + 1, 14).setValue(body.firmaLat || '');    // firmaLat
      sheet.getRange(i + 1, 15).setValue(body.firmaLng || '');    // firmaLng
      sheet.getRange(i + 1, 16).setValue(body.firmaDireccion || ''); // firmaDireccion
      sheet.getRange(i + 1, 17).setValue(body.firmaUserAgent || ''); // firmaUserAgent
      sheet.getRange(i + 1, 18).setValue(hashHex);                 // firmaHash

      try {
        logActivity_('✍️', firmaNombre, 'firmó (evidencia: ' + (body.firmaIp || '—') + ')', data[i][2], hashHex.slice(0, 12));
      } catch (e) {}

      return {
        success: true,
        firmadoEn: nowIso,
        firmaNombre: firmaNombre,
        firmaIp: body.firmaIp || '',
        firmaDireccion: body.firmaDireccion || '',
        hash: hashHex,
        titulo: data[i][2]
      };
    }
  }
  return { success: false, error: 'Documento no encontrado o no es tuyo' };
}

// ─── Helpers ────────────────────────────────────────────────

/**
 * Notifica por email al empleado que tiene un documento pendiente.
 */
function notifyDocumentEmail_(email, titulo, tipo) {
  const subject = '🍇 Cosecha: Nuevo documento ' + (tipo || 'para revisar');
  const body = 'Hola,\n\nTienes un nuevo documento pendiente en Cosecha:\n\n' +
               '    ' + titulo + '\n\n' +
               'Por favor, revísalo y fírmalo lo antes posible desde la app.\n\n' +
               '— Cosecha · En Copa de Balón';

  const html = '<div style="font-family:-apple-system,sans-serif;max-width:480px;margin:0 auto;padding:36px 20px;">' +
    '<div style="text-align:center;margin-bottom:24px;">' +
    '<div style="font-size:42px;">🍇</div>' +
    '<h1 style="margin:10px 0 2px;color:#9B2C3E;font-size:24px;font-weight:800;">Cosecha</h1>' +
    '<p style="color:#999;font-size:10px;margin:0;letter-spacing:1.2px;">EN COPA DE BALÓN</p>' +
    '</div>' +
    '<div style="background:#F7F7F8;border:1px solid #E5E5E7;border-radius:14px;padding:26px;">' +
    '<p style="color:#555;margin:0 0 12px;font-size:13px;text-transform:uppercase;letter-spacing:.5px;font-weight:700;">📄 Nuevo documento</p>' +
    '<p style="color:#111;margin:0 0 18px;font-size:18px;font-weight:700;line-height:1.4;">' + titulo + '</p>' +
    '<p style="color:#555;margin:0;font-size:13px;line-height:1.6;">Entra en Cosecha desde tu móvil u ordenador para revisarlo y firmarlo.</p>' +
    '</div>' +
    '<p style="color:#AAA;font-size:11px;text-align:center;margin-top:20px;">Recibes este email porque eres empleado de En Copa de Balón.</p>' +
    '</div>';

  GmailApp.sendEmail(email, subject, body, { htmlBody: html, name: 'Cosecha RRHH' });
}
