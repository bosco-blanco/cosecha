/**
 * ============================================================
 * Cosecha CRM - Calendar.gs
 * Integración con Google Calendar.
 * Gestiona eventos del calendario principal del usuario.
 * ============================================================
 */

/**
 * Lista los eventos del calendario principal entre dos fechas.
 * @param {Date} startDate - Fecha de inicio.
 * @param {Date} endDate - Fecha de fin.
 * @returns {Object[]} Array de eventos serializados.
 */
function listEvents(startDate, endDate) {
  const calendar = CalendarApp.getDefaultCalendar();
  const events   = calendar.getEvents(startDate, endDate);

  return events.map(function(event) {
    return serializeEvent_(event);
  });
}

/**
 * Crea un nuevo evento en el calendario principal.
 * @param {string} title - Título del evento.
 * @param {Date} start - Fecha y hora de inicio.
 * @param {Date} end - Fecha y hora de fin.
 * @param {string[]} attendees - Lista de emails de asistentes.
 * @param {string} description - Descripción del evento.
 * @param {string} location - Ubicación del evento.
 * @returns {Object} Evento creado serializado.
 */
function createEvent(title, start, end, attendees, description, location) {
  const calendar = CalendarApp.getDefaultCalendar();

  // Crear el evento
  const event = calendar.createEvent(title, start, end, {
    description: description || '',
    location:    location    || '',
    guests:      (attendees && attendees.length > 0) ? attendees.join(',') : ''
  });

  Logger.log('Evento creado: ' + event.getId() + ' - ' + title);

  return serializeEvent_(event);
}

/**
 * Actualiza un evento existente en el calendario.
 * @param {string} eventId - ID del evento de Google Calendar.
 * @param {Object} updates - Campos a actualizar (title, start, end, description, location).
 * @returns {Object} Evento actualizado serializado.
 */
function updateEvent(eventId, updates) {
  const calendar = CalendarApp.getDefaultCalendar();
  const event    = calendar.getEventById(eventId);

  if (!event) {
    return { error: true, message: 'Evento no encontrado con ID: ' + eventId };
  }

  // Aplicar actualizaciones
  if (updates.title) {
    event.setTitle(updates.title);
  }

  if (updates.description !== undefined) {
    event.setDescription(updates.description);
  }

  if (updates.location !== undefined) {
    event.setLocation(updates.location);
  }

  if (updates.start && updates.end) {
    event.setTime(new Date(updates.start), new Date(updates.end));
  }

  // Añadir nuevos asistentes (sin eliminar los existentes)
  if (updates.attendees && Array.isArray(updates.attendees)) {
    updates.attendees.forEach(function(email) {
      try {
        event.addGuest(email);
      } catch (e) {
        Logger.log('No se pudo añadir asistente: ' + email + ' - ' + e.message);
      }
    });
  }

  Logger.log('Evento actualizado: ' + eventId);

  return serializeEvent_(event);
}

/**
 * Elimina un evento del calendario.
 * @param {string} eventId - ID del evento de Google Calendar.
 * @returns {Object} Confirmación de eliminación.
 */
function deleteEvent(eventId) {
  const calendar = CalendarApp.getDefaultCalendar();
  const event    = calendar.getEventById(eventId);

  if (!event) {
    return { error: true, message: 'Evento no encontrado con ID: ' + eventId };
  }

  const title = event.getTitle();
  event.deleteEvent();

  Logger.log('Evento eliminado: ' + eventId + ' - ' + title);

  return { deleted: true, eventId: eventId, title: title };
}

/**
 * Crea un evento en el calendario a partir de los datos de una reunión del CRM.
 * Si la reunión ya tiene un calendarEventId, actualiza en lugar de crear.
 * @param {Object} meetingData - Datos de la reunión.
 * @returns {Object} Evento creado/actualizado y reunión vinculada.
 */
function syncMeetingToCalendar(meetingData) {
  // Preparar fechas
  const fecha    = new Date(meetingData.fecha);
  const duracion = parseInt(meetingData.duracion, 10) || 60; // minutos
  const fin      = new Date(fecha.getTime() + duracion * 60 * 1000);

  // Preparar asistentes
  var asistentes = [];
  if (meetingData.asistentes) {
    if (typeof meetingData.asistentes === 'string') {
      try {
        asistentes = JSON.parse(meetingData.asistentes);
      } catch (e) {
        asistentes = meetingData.asistentes.split(',').map(function(s) { return s.trim(); });
      }
    } else if (Array.isArray(meetingData.asistentes)) {
      asistentes = meetingData.asistentes;
    }
  }

  // Construir descripción con info del CRM
  var descripcion = '📋 Reunión registrada en Cosecha CRM\n\n';
  if (meetingData.resumen)     descripcion += '📝 Resumen: ' + meetingData.resumen + '\n\n';
  if (meetingData.puntosClave) descripcion += '🔑 Puntos clave: ' + meetingData.puntosClave + '\n\n';
  if (meetingData.acciones)    descripcion += '✅ Acciones: ' + meetingData.acciones + '\n';

  // Verificar si ya existe un evento vinculado
  if (meetingData.calendarEventId) {
    var result = updateEvent(meetingData.calendarEventId, {
      title:       meetingData.titulo,
      start:       fecha,
      end:         fin,
      description: descripcion,
      location:    meetingData.ubicacion || '',
      attendees:   asistentes
    });
    return { event: result, meetingId: meetingData.meetingId || meetingData.id };
  }

  // Crear nuevo evento
  var event = createEvent(
    meetingData.titulo || 'Reunión Cosecha CRM',
    fecha,
    fin,
    asistentes,
    descripcion,
    meetingData.ubicacion || ''
  );

  return { event: event, meetingId: meetingData.meetingId || meetingData.id };
}

/**
 * Obtiene los eventos de los próximos N días.
 * @param {number} days - Número de días a consultar (por defecto 7).
 * @returns {Object[]} Array de eventos serializados.
 */
function getUpcomingEvents(days) {
  const numDays = days || 7;
  const now     = new Date();
  const end     = new Date();
  end.setDate(end.getDate() + numDays);

  return listEvents(now, end);
}

// ─── Helpers ────────────────────────────────────────────────

/**
 * Serializa un evento de Google Calendar a un objeto plano.
 * @param {CalendarEvent} event - Evento de Google Calendar.
 * @returns {Object} Objeto con los datos del evento.
 */
function serializeEvent_(event) {
  var guests = event.getGuestList().map(function(guest) {
    return {
      email:  guest.getEmail(),
      name:   guest.getName(),
      status: guest.getGuestStatus().toString()
    };
  });

  return {
    id:          event.getId(),
    title:       event.getTitle(),
    description: event.getDescription(),
    location:    event.getLocation(),
    start:       event.getStartTime().toISOString(),
    end:         event.getEndTime().toISOString(),
    allDay:      event.isAllDayEvent(),
    guests:      guests,
    creator:     event.getCreators().join(', '),
    color:       event.getColor(),
    url:         event.getOriginalCalendarId()
      ? 'https://calendar.google.com/calendar/r/eventedit/' + event.getId()
      : ''
  };
}
