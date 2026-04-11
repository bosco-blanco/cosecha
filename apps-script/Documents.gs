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
 * Firma electrónicamente un documento.
 * Según art. 10 Ley 6/2020, es firma electrónica simple con validez contractual.
 */
function signDocument(body) {
  const id = body.id;
  const email = String(body.email || '').toLowerCase().trim();
  if (!id) return { success: false, error: 'ID requerido' };

  const sheet = getTabSheet_('Documentos');
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id && String(data[i][1]).toLowerCase() === email) {
      sheet.getRange(i + 1, 7).setValue('firmado');
      sheet.getRange(i + 1, 10).setValue(new Date().toISOString());

      try {
        logActivity_('✍️', emailToName_(email), 'firmó documento', data[i][2], '');
      } catch (e) {}

      return { success: true, firmadoEn: new Date().toISOString() };
    }
  }
  return { success: false, error: 'No encontrado' };
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
