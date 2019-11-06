module AlertHelper
  def check_alert_2shifts_jointed(employee)
    return false if employee.nil?

    employee_available_hours = get_current_employee_available_hours(employee)
    # any negative values indicate more than 1 hours was allocated simultaneously
    result = employee_available_hours.any? { |_day, ah| (0..23).all? { |i| ah["hour_#{i}".to_sym] < 0.0 } }

    if result
      alert = Alert.new
      alert.employee_id = employee.id
      alert.alert_type = '2shifts_jointed'
      alert.message = "El empleado #{link_employee(employee.id)} tiene una colisión de jornadas (2 a la misma hora)"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: '2shifts_jointed', employee_id: employee.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_availability_hours_with_shifts(employee)
    return false if employee.nil?

    if employee.shifts.all? { |shift| employee_availability_matches_shift(employee, shift) }
      existing_alert = Alert.where(alert_type: 'availability_hours_mismatch_shift', employee_id: employee.id)
      existing_alert.delete unless existing_alert.nil?
    else
      alert = Alert.new
      alert.employee_id = employee.id
      alert.alert_type = 'availability_hours_mismatch_shift'
      alert.message = "La disponibilidad horaria del empleado #{link_employee(employee.id)} no coincide con los turnos que tiene asignados"
      alert.save if alert.valid?
    end

    defined?(alert)
  end

  def check_availability_hours_with_replacements(employee)
    return false if employee.nil?

    if employee.shift_replacements.all? { |replacement| replacement[:absence_date] < Date.today || employee_availability_matches_shift(employee, replacement.shift, date_to_week_day(replacement[:absence_date])) }
      existing_alert = Alert.where(alert_type: 'availability_hours_mismatch_replacement', employee_id: employee.id)
      existing_alert.delete unless existing_alert.nil?
    else
      alert = Alert.new
      alert.employee_id = employee.id
      alert.alert_type = 'availability_hours_mismatch_replacement'
      alert.message = "La disponibilidad horaria del empleado #{link_employee(employee.id)} no coincide con las suplencias que tiene asignadas"
      alert.save if alert.valid?
    end

    defined?(alert)
  end


  def check_alert_too_many_hours(employee)
    return false if employee.nil?

    if employee_assigned_hours(employee) > employee[:max_weekly_hours]
      alert = Alert.new
      alert.employee_id = employee.id
      alert.alert_type = 'too_many_hours'
      alert.message = "El empleado #{link_employee(employee.id)} tiene más de #{employee[:max_weekly_hours]} horas asignadas"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'too_many_hours', employee_id: employee.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_alert_empty_shift(shift)
    return false if shift.nil?

    if shift.employee_id.nil?
      alert = Alert.new
      alert.shift_id = shift.id
      alert.alert_type = 'empty_shift'
      alert.message = "No hay empleados en el turno ##{shift.id} de #{link_location(shift.location.id)}, cliente #{link_client(shift.client.id)}"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'empty_shift', shift_id: shift.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_alert_location_with_missing_backups(location)
    return false if location.nil?

    if location.shift_backups.any? { |s| s[:employee_id].nil? }
      alert = Alert.new
      alert.location_id = location[:id]
      alert.alert_type = 'empty_shift_backup'
      alert.message = "Falta completar pedidos de refuerzo de #{link_location(location[:id])}, cliente #{link_client(location.client[:id])}"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'empty_shift_backup', location_id: location[:id])
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_alert_invalid_type(shift)
    return false if shift.nil?

    if !shift.employee_id.nil? && shift.type.type != shift.employee.type.type
      alert = Alert.new
      alert.shift_id = shift.id
      alert.alert_type = 'invalid_type'
      alert.message = "Asignación inválida (tipo) en el turno ##{shift.id} de #{link_location(shift.location.id)}, cliente #{link_client(shift.client.id)}"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'invalid_type', shift_id: shift.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_alert_needs_replacement(shift)
    return false if shift.nil?

    if shift.absences.any? { |absence| absence.absence_date >= Date.today && absence.replacement_id.nil? }
      alert = Alert.new
      alert.shift_id = shift.id
      alert.alert_type = 'needs_replacement'
      alert.message = "Se necesita un suplente para el turno ##{shift.id} de #{link_location(shift.location.id)}, cliente #{link_client(shift.client.id)}"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'needs_replacement', shift_id: shift.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def check_alert_contract_needs_atention(location)
    return false if location.nil?

    # trigger?
    should_trigger = false

    # min employees
    if location.min_employees > 0 && location.shifts.reject { |s| s.archived || s.employee_id.nil? }.uniq { |s| s.employee_id }.count < location.min_employees
      should_trigger = true
    end

    # supervisor needed
    if location.supervisor_needed && location.shifts.any? { |s| !s.archived && !s.type.type =~ /Supervisor/ && !s.employee_id.nil? }
      should_trigger = true
    end

    if should_trigger
      alert = Alert.new
      alert.location_id = location.id
      alert.alert_type = 'contract_needs_atention'
      alert.message = "Hay un problema con el contrato de #{link_location(location.id)}, cliente #{link_client(location.client.id)}"
      alert.save if alert.valid?
    else
      existing_alert = Alert.where(alert_type: 'contract_needs_atention', location_id: location.id)
      existing_alert.delete unless existing_alert.nil?
    end

    defined?(alert)
  end

  def rescan_all_alerts
    Employee.each do |employee|
      check_alert_2shifts_jointed(employee)
      puts employee[:id]
      check_availability_hours_with_shifts(employee)
      check_availability_hours_with_replacements(employee)
      check_alert_too_many_hours(employee)
    end
    Shift.each do |shift|
      check_alert_empty_shift(shift)
      check_alert_invalid_type(shift)
      check_alert_needs_replacement(shift)
    end
    Location.each do |location|
      check_alert_location_with_missing_backups(location)
      check_alert_contract_needs_atention(location)
    end
    nil
  end
end