/**
 * ============================================================
 * Cosecha CRM - Slack.gs
 * Integración con Slack mediante Incoming Webhooks.
 * Envía notificaciones formateadas con Block Kit.
 * Tema visual: vino / uva 🍇
 * ============================================================
 */

/**
 * Envía un mensaje a Slack mediante un webhook.
 * @param {string} webhookUrl - URL del Incoming Webhook de Slack.
 * @param {string} channel - Canal de destino (e.g. #cosecha-crm).
 * @param {string} message - Texto del mensaje (fallback).
 * @param {Object[]|null} blocks - Bloques de Slack Block Kit (opcional).
 * @returns {Object} Resultado del envío.
 */
function sendSlack(webhookUrl, channel, message, blocks) {
  if (!webhookUrl) {
    return { sent: false, error: 'No se proporcionó webhookUrl. Configúrala en la pestaña Config con clave SLACK_WEBHOOK_URL.' };
  }

  var payload = {
    text: message || 'Notificación de Cosecha CRM'
  };

  // El canal se puede omitir si el webhook ya está configurado para uno específico
  if (channel) {
    payload.channel = channel;
  }

  // Usar bloques si se proporcionan
  if (blocks && blocks.length > 0) {
    payload.blocks = blocks;
  }

  try {
    var response = UrlFetchApp.fetch(webhookUrl, {
      method:      'post',
      contentType: 'application/json',
      payload:     JSON.stringify(payload),
      muteHttpExceptions: true
    });

    var code = response.getResponseCode();
    var body = response.getContentText();

    if (code === 200 && body === 'ok') {
      Logger.log('Mensaje enviado a Slack: ' + message);
      return { sent: true, channel: channel };
    } else {
      Logger.log('Error al enviar a Slack: ' + code + ' - ' + body);
      return { sent: false, error: 'Slack respondió con código ' + code + ': ' + body };
    }
  } catch (err) {
    Logger.log('Excepción al enviar a Slack: ' + err.message);
    return { sent: false, error: err.message };
  }
}

/**
 * Notifica la finalización de una tarea.
 * @param {Object} task - Datos de la tarea completada.
 * @param {string} channel - Canal de Slack.
 * @returns {Object} Resultado del envío.
 */
function notifyTaskComplete(task, channel) {
  const webhookUrl = getConfig_('SLACK_WEBHOOK_URL');
  const msg = formatSlackMessage('task_complete', task);
  return sendSlack(webhookUrl, channel || getConfig_('SLACK_CHANNEL') || '#cosecha-crm', msg.text, msg.blocks);
}

/**
 * Notifica el resumen de una reunión con sus puntos clave.
 * @param {Object} meeting - Datos de la reunión.
 * @param {string} channel - Canal de Slack.
 * @returns {Object} Resultado del envío.
 */
function notifyMeetingSummary(meeting, channel) {
  const webhookUrl = getConfig_('SLACK_WEBHOOK_URL');
  const msg = formatSlackMessage('meeting_summary', meeting);
  return sendSlack(webhookUrl, channel || getConfig_('SLACK_CHANNEL') || '#cosecha-crm', msg.text, msg.blocks);
}

/**
 * Notifica un cambio de etapa en un deal.
 * @param {Object} deal - Datos del deal con la nueva etapa.
 * @param {string} channel - Canal de Slack.
 * @returns {Object} Resultado del envío.
 */
function notifyDealUpdate(deal, channel) {
  const webhookUrl = getConfig_('SLACK_WEBHOOK_URL');
  const msg = formatSlackMessage('deal_update', deal);
  return sendSlack(webhookUrl, channel || getConfig_('SLACK_CHANNEL') || '#cosecha-crm', msg.text, msg.blocks);
}

/**
 * Notifica la creación de un nuevo contacto.
 * @param {Object} contact - Datos del contacto creado.
 * @param {string} channel - Canal de Slack.
 * @returns {Object} Resultado del envío.
 */
function notifyNewContact(contact, channel) {
  const webhookUrl = getConfig_('SLACK_WEBHOOK_URL');
  const msg = formatSlackMessage('new_contact', contact);
  return sendSlack(webhookUrl, channel || getConfig_('SLACK_CHANNEL') || '#cosecha-crm', msg.text, msg.blocks);
}

/**
 * Construye mensajes formateados de Slack con Block Kit.
 * Cada tipo de notificación tiene su propio formato visual.
 * @param {string} type - Tipo de notificación: task_complete, meeting_summary, deal_update, new_contact.
 * @param {Object} data - Datos para la notificación.
 * @returns {Object} Objeto con text (fallback) y blocks (Block Kit).
 */
function formatSlackMessage(type, data) {
  var text   = '';
  var blocks = [];

  switch (type) {

    // ─── Tarea completada ───────────────────────────────
    case 'task_complete':
      text = '🍇 Tarea completada: ' + (data.titulo || 'Sin título');
      blocks = [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: '🍇 Tarea completada',
            emoji: true
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*Tarea:*\n' + (data.titulo || 'Sin título')
            },
            {
              type: 'mrkdwn',
              text: '*Prioridad:*\n' + (data.prioridad || 'Normal')
            },
            {
              type: 'mrkdwn',
              text: '*Asignados:*\n' + (data.asignados || 'Sin asignar')
            },
            {
              type: 'mrkdwn',
              text: '*Proyecto:*\n' + (data.proyecto || 'General')
            }
          ]
        },
        buildContextBlock_('Cosecha CRM • En Copa de Balón')
      ];

      if (data.descripcion) {
        blocks.splice(2, 0, {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '> ' + data.descripcion
          }
        });
      }
      break;

    // ─── Resumen de reunión ─────────────────────────────
    case 'meeting_summary':
      text = '🎙️ Resumen de reunión: ' + (data.titulo || 'Sin título');
      blocks = [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: '🎙️ Resumen de reunión',
            emoji: true
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*Reunión:*\n' + (data.titulo || 'Sin título')
            },
            {
              type: 'mrkdwn',
              text: '*Fecha:*\n' + (data.fecha || 'Sin fecha')
            },
            {
              type: 'mrkdwn',
              text: '*Duración:*\n' + (data.duracion || '?') + ' min'
            },
            {
              type: 'mrkdwn',
              text: '*Canal:*\n' + (data.canal || 'Presencial')
            }
          ]
        }
      ];

      // Añadir resumen si existe
      if (data.resumen) {
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*📝 Resumen:*\n' + data.resumen
          }
        });
      }

      // Añadir puntos clave
      if (data.puntosClave) {
        var puntos = data.puntosClave;
        if (typeof puntos === 'string') {
          try { puntos = JSON.parse(puntos); } catch (e) { /* dejar como string */ }
        }
        var puntosText = Array.isArray(puntos)
          ? puntos.map(function(p) { return '• ' + p; }).join('\n')
          : puntos;
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*🔑 Puntos clave:*\n' + puntosText
          }
        });
      }

      // Añadir acciones
      if (data.acciones) {
        var acciones = data.acciones;
        if (typeof acciones === 'string') {
          try { acciones = JSON.parse(acciones); } catch (e) { /* dejar como string */ }
        }
        var accionesText = Array.isArray(acciones)
          ? acciones.map(function(a) { return '☑️ ' + a; }).join('\n')
          : acciones;
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*✅ Acciones:*\n' + accionesText
          }
        });
      }

      blocks.push(buildContextBlock_('Cosecha CRM • En Copa de Balón'));
      break;

    // ─── Actualización de deal ──────────────────────────
    case 'deal_update':
      text = '💰 Deal actualizado: ' + (data.titulo || 'Sin título');

      // Mapeo de etapas a nombres legibles
      var etapasNombres = {
        'lead':             '🔵 Lead',
        'calificado':       '🟡 Calificado',
        'propuesta':        '🟠 Propuesta',
        'negociacion':      '🔴 Negociación',
        'cerrado-ganado':   '🟢 Cerrado (Ganado)',
        'cerrado-perdido':  '⚫ Cerrado (Perdido)'
      };

      var etapaDisplay = etapasNombres[data.etapa] || data.etapa || 'Sin etapa';
      var valorDisplay = data.valor
        ? new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' }).format(data.valor)
        : '0 €';

      blocks = [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: '💰 Deal actualizado',
            emoji: true
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*Deal:*\n' + (data.titulo || 'Sin título')
            },
            {
              type: 'mrkdwn',
              text: '*Etapa:*\n' + etapaDisplay
            },
            {
              type: 'mrkdwn',
              text: '*Valor:*\n' + valorDisplay
            },
            {
              type: 'mrkdwn',
              text: '*Probabilidad:*\n' + (data.probabilidad || 0) + '%'
            },
            {
              type: 'mrkdwn',
              text: '*Contacto:*\n' + (data.contactoNombre || 'Sin contacto')
            },
            {
              type: 'mrkdwn',
              text: '*Asignado:*\n' + (data.asignado || 'Sin asignar')
            }
          ]
        },
        buildContextBlock_('Cosecha CRM • En Copa de Balón')
      ];

      // Destacar si es un deal ganado
      if (data.etapa === 'cerrado-ganado') {
        blocks.splice(1, 0, {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '🎉 *¡Deal cerrado con éxito!* ' + valorDisplay
          }
        });
      }
      break;

    // ─── Nuevo contacto ─────────────────────────────────
    case 'new_contact':
      text = '👤 Nuevo contacto: ' + (data.nombre || 'Sin nombre');

      var tipoEmojis = {
        'cliente':   '🏢',
        'proveedor': '📦',
        'partner':   '🤝',
        'lead':      '🎯'
      };
      var tipoEmoji = tipoEmojis[data.tipo] || '👤';

      blocks = [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: '👤 Nuevo contacto añadido',
            emoji: true
          }
        },
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: '*Nombre:*\n' + (data.nombre || 'Sin nombre')
            },
            {
              type: 'mrkdwn',
              text: '*Tipo:*\n' + tipoEmoji + ' ' + (data.tipo || 'Sin tipo')
            },
            {
              type: 'mrkdwn',
              text: '*Empresa:*\n' + (data.empresa || 'No especificada')
            },
            {
              type: 'mrkdwn',
              text: '*Email:*\n' + (data.email || 'No proporcionado')
            }
          ]
        }
      ];

      if (data.notas) {
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: '*📋 Notas:*\n> ' + data.notas
          }
        });
      }

      blocks.push(buildContextBlock_('Cosecha CRM • En Copa de Balón'));
      break;

    // ─── Tipo desconocido ───────────────────────────────
    default:
      text = '🍇 Cosecha CRM: ' + JSON.stringify(data);
      blocks = [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: text
          }
        }
      ];
  }

  return { text: text, blocks: blocks };
}

// ─── Helpers internos ───────────────────────────────────────

/**
 * Construye un bloque de contexto con el branding de Cosecha.
 * @param {string} text - Texto del contexto.
 * @returns {Object} Bloque de contexto de Slack.
 */
function buildContextBlock_(text) {
  return {
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: '🍷 ' + text + ' • ' + new Date().toLocaleString('es-ES', { timeZone: 'Europe/Madrid' })
      }
    ]
  };
}
