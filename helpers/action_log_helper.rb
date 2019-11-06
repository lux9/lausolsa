module ActionLogHelper
  def action_log_for_employee_absence(employee_absence, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = nil
    action_log.location_id = nil
    action_log.employee_id = employee_absence.employee_id

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Desde: #{human_readable_date(employee_absence.absence_start_date)}<br>" \
                         "Hasta: #{human_readable_date(employee_absence.absence_end_date)}<br>" \
                         "Empleado ausente: #{link_employee(employee_absence.employee_id)}"
    action_log
  end

  def action_log_for_absence(absence, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = absence.client_id
    action_log.location_id = absence.location_id
    action_log.employee_id = absence.replacement_id.nil? ? absence.absence_id : absence.replacement_id

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Día de suplencia: #{human_readable_date(absence.absence_date, absence.shift.start_time, absence.shift.end_time)}<br>" \
                         "Empleado ausente: #{link_employee(absence.absence_id)}<br>" \
                         "Empleado suplente: #{absence.replacement_id.nil? ? 'Ninguno' : link_employee(absence.replacement_id)}<br>" \
                         "Trabajo: #{absence.shift.type[:type]} en #{link_location(absence.location_id)}<br>" \
                         "Cliente #{link_client(absence.client_id)}"
    action_log
  end

  def action_log_for_shift(shift, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = shift.client_id
    action_log.location_id = shift.location_id
    action_log.employee_id = shift.employee_id

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Turno: #{shift_readable_dates(shift)}<br>" \
                         "Empleado asignado: #{shift.employee_id.nil? ? 'Ninguno' : link_employee(shift.employee_id)}<br>" \
                         "Trabajo: #{shift.type[:type]} en #{link_location(shift.location_id)}<br>" \
                         "Cliente #{link_client(shift.client_id)}"
    action_log
  end

  def action_log_for_location(location, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = location.client_id
    action_log.location_id = location.id
    action_log.employee_id = nil

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Estación de trabajo: #{link_location(location.id)}<br>" \
                         "Turnos de Trabajo: #{location.shifts.count}<br>" \
                         "Cliente #{link_client(location.client_id)}"
    action_log
  end

  def action_log_for_employee(employee, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = nil
    action_log.location_id = nil
    action_log.employee_id = employee.id

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Empleado: #{link_employee(employee.id)}<br>" \
                         "Turnos de Trabajo: #{employee.shifts.count}<br>" \
                         "Ausencias recientes: #{employee.shift_absences.count}<br>" \
                         "Suplencias recientes: #{employee.shift_replacements.count}"
    action_log
  end

  def action_log_for_client(client, message)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = client.id
    action_log.location_id = nil
    action_log.employee_id = nil

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = "Cliente: #{link_client(client.id)}<br>" \
                         "Estaciones de trabajo: #{client.locations.count}"
    action_log
  end

  def action_log_simple(message, details = nil)
    action_log = ActionLog.new
    action_log.date_time = DateTime.now
    action_log.client_id = nil
    action_log.location_id = nil
    action_log.employee_id = nil

    action_log.admin_id = @user.id
    action_log.message = message
    action_log.details = details.nil? ? message : details
    action_log
  end
end
