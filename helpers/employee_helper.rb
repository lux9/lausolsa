module EmployeeHelper
  def employee_import_fields
    {
      first_name: 'Nombre',
      last_name: 'Apellido',
      cuit: 'CUIT',
      file_number: 'Nro de Legajo',
      gender: 'Género',
      phone_mobile: 'Teléfono celular',
      phone_home: 'Teléfono fijo',
      birthday: 'Fecha Nacimiento',
      marital_status: 'Estado Civil',
      address_street: 'Dirección (calle)',
      address_street_between: 'Dirección (entre calles)',
      address_number: 'Dirección (nro)',
      address_extra: 'Dirección (extra)',
      address_cp: 'Dirección (CP)',
      address_city: 'Dirección (ciudad)',
      address_province: 'Dirección (provincia)',
      address_country: 'Dirección (país)',
      type_id: 'Tipo de Trabajo',
      cbu: 'CBU',
      join_date: 'Fecha de ingreso',
      worker_union: 'Sindicato',
      works_holidays: 'Trabaja Feriados',
      max_weekly_hours: 'Horas que trabaja por semana',
      comment: 'Comentario'
    }
  end

  def employee_extra_fields
    {
      shift_absence: 'Ausencias a turnos',
      shift_replacement: 'Suplencias a turnos',
      shift_backup: 'Refuerzos cubiertos',
      shift_weekly_hours: 'Horas asignadas a turnos'
    }
  end

  def employee_default_available_hours(employee)
    available_hours = {}

    %i[monday tuesday wednesday thursday friday].each do |day|
      available_hours[day] = EmployeeAvailableHours.new
      available_hours[day][:employee_id] = employee[:id]
      available_hours[day][:day_of_week] = day.to_s
      (7..19).each do |i|
        available_hours[day]["hour_#{i}".to_sym] = 1.0
      end
    end

    available_hours
  end

  def employee_assigned_hours(employee)
    return 0.0 if employee.shifts.count.zero?

    hours = employee.shifts
                    .reject { |s| s[:end_date] <= Date.today }
                    .map { |s| s[:weekly_hours] }
                    .reduce(:+)

    hours.is_a?(Numeric) ? hours.to_f : 0.0
  end

  def employee_setup(employee, params)
    Employee.columns.each { |key| employee[key] = params[key] if !params[key].nil? && key != :id }

    employee[:worker_union] = (!params[:worker_union].nil? && params[:worker_union] =~ /si|sí|on/i)
    employee[:works_holidays] = (!params[:works_holidays].nil? && params[:works_holidays] =~ /si|sí|on/i)

    employee
  end

  def employee_filters(employees, params)
    employees = employees.where(archived: false) unless params[:show_archived] == '1'

    unless params[:starting_letter].nil?
      name_search = "#{params[:starting_letter]}%"
      employees = employees.where{ Sequel.ilike(:last_name, name_search) }
      return employees
    end

    if params[:filter_by_name] == 'on' && !params[:name].empty?
      params[:name].split.each do |name_filter|
        name_search = "%#{name_filter}%".to_s
        employees = employees.where{ Sequel.ilike(:first_name, name_search) | Sequel.ilike(:last_name, name_search)}
      end
    end

    if params[:filter_by_type] == 'on'
      job_type = JobType.where(type: params[:type]).first
      employees = employees.where(type_id: job_type[:id]) unless job_type.nil?
    end

    employees = employees.where(gender: params[:gender]) if params[:filter_by_gender] == 'on'
    employees = employees.where(address_city: params[:address_city]) if params[:filter_by_city] == 'on'
    employees = employees.where(address_province: params[:address_province]) if params[:filter_by_province] == 'on'
    employees = employees.where(address_country: params[:address_country]) if params[:filter_by_country] == 'on'

    employees
  end

  def get_current_employee_available_hours(employee, ignore_shift = nil)
    available_hours = {}
    employee.available_hours.each do |ah|
      available_hours[ah[:day_of_week].to_sym] = {}
      (0..23).each do |i|
        available_hours[ah[:day_of_week].to_sym]["hour_#{i}".to_sym] = 0.0 + ah["hour_#{i}".to_sym]
      end
    end
    return {} if available_hours == {}

    employee.shifts.each do |shift|
      next if shift == ignore_shift
      next if shift[:archived] || shift[:end_date] <= Date.today

      shift.work_hours.each do |wh|
        # there is a shift assigned not maching availability hours, must be fixed first
        return {} if available_hours[wh[:day_of_week].to_sym].nil?

        (0..23).each do |i|
          available_hours[wh[:day_of_week].to_sym]["hour_#{i}".to_sym] -= wh["hour_#{i}".to_sym]
        end
      end
    end

    # TODO: get replacements for this week somehow?
    available_hours
  end

  def employee_availability_matches_shift(employee, shift, single_day = nil)
    return true if shift.archived

    available_hours = get_current_employee_available_hours(employee, shift)
    return false if available_hours == {}

    new_shift_work_hours = {}
    shift.work_hours.each { |swh| new_shift_work_hours[swh[:day_of_week].to_sym] = swh }

    days = %i[monday tuesday wednesday thursday friday saturday sunday monday]
    (0..6).each do |day_index|
      day = days[day_index]

      next if !single_day.nil? && single_day.to_sym != day
      next unless shift[day]
      return false if available_hours[day].nil?

      start_hour = shift[:start_time].to_s[0..1].to_i
      end_hour = shift[:end_time].to_s[0..1].to_i

      # daytime shift
      if start_hour <= end_hour || end_hour == 0
        return false unless (start_hour..end_hour).all? { |i| new_shift_work_hours[day]["hour_#{i}".to_sym] <= available_hours[day]["hour_#{i}".to_sym] }
      # night shift (across 2 days)
      else
        return false unless (start_hour..23).all? { |i| new_shift_work_hours[day]["hour_#{i}".to_sym] <= available_hours[day]["hour_#{i}".to_sym] }

        day = days[day_index + 1]
        return false if available_hours[day].nil?
        return false unless (0..end_hour).all? { |i| new_shift_work_hours[day]["hour_#{i}".to_sym] <= available_hours[day]["hour_#{i}".to_sym] }
      end
    end

    true
  end

  def available_employees_for_shift(shift, employees = Employee)
    available_employees = employees

    # only active employees
    available_employees = available_employees.find_all { |e| !e[:archived] }

    # are holidays required?
    available_employees = available_employees.find_all { |e| e[:works_holidays] } if shift[:includes_holidays]

    # matching type?
    available_employees = available_employees.find_all { |e| shift[:type_id] == e[:type_id] }

    # enough free hours for this shift?
    available_employees = available_employees.find_all { |e| employee_assigned_hours(e) + shift[:weekly_hours] <= e[:max_weekly_hours] }

    # available at that time of day?
    available_employees = available_employees.find_all { |employee| employee_availability_matches_shift(employee, shift) }

    # show employees with more free time hours
    available_employees.sort_by! { |e| e[:max_weekly_hours] + (e[:max_weekly_hours] - employee_assigned_hours(e)) }
  end

  def employee_availability_matches_shift_backup(employee, shift_backup)
    day_to_check = date_to_week_day(shift_backup[:date]).to_sym
    available_hours = get_current_employee_available_hours(employee)

    start_hour = shift_backup[:start_time].to_s[0..1].to_i
    end_hour = shift_backup[:end_time].to_s[0..1].to_i

    new_backup_wh = {}
    shift_backup.work_hours.each { |swh| new_backup_wh[swh[:day_of_week].to_sym] = swh }

    days = %i[monday tuesday wednesday thursday friday saturday sunday monday]
    (0..6).each do |day_index|
      day = days[day_index]
      next if day_to_check != day
      return false if available_hours[day].nil?

      # daytime shift
      if start_hour < end_hour || end_hour == 0
        return (0..23).all? { |i| new_backup_wh[day]["hour_#{i}".to_sym] <= available_hours[day]["hour_#{i}".to_sym] }
      end

      # night shift (first day)
      return false unless (start_hour..23).all? { |i| new_backup_wh[day]["hour_#{i}".to_sym] <= available_hours[day]["hour_#{i}".to_sym] }

      # night shift (final day)
      return (0..end_hour).all? { |i| new_backup_wh[day]["hour_#{i}".to_sym] <= available_hours[days[day_index + 1]]["hour_#{i}".to_sym] }
    end

    # failsafe for non matching days
    false
  end

  def available_employees_for_shift_backup(shift_backup, employees = Employee)
    available_employees = employees

    # only active employees
    available_employees = available_employees.find_all { |e| !e[:archived] }

    # are holidays required?
    available_employees = available_employees.find_all { |e| e[:works_holidays] } unless Holiday.where(holiday_date: shift_backup[:date]).count.zero?

    # matching type?
    available_employees = available_employees.find_all { |e| shift_backup.type_id == e.type_id }

    # free time this week? (disabled for now)
    # available_employees = available_employees.find_all { |e| employee_assigned_hours(e) + shift_backup[:hours] <= e[:max_weekly_hours] }

    # available at that time?
    available_employees = available_employees.find_all { |employee| employee_availability_matches_shift_backup(employee, shift_backup) }

    # show employees with more free time first
    available_employees.sort_by! { |e| e[:max_weekly_hours] + (e[:max_weekly_hours] - employee_assigned_hours(e)) }
  end

  def available_employees_for_absences(shift_absences, employees = Employee)
    available_employees = employees

    # only active employees
    available_employees = available_employees.select { |e| !e[:archived] }

    shift_absences.all? do |absence|
      break if available_employees.empty?

      shift = absence.shift

      # is this on a holiday?
      if !Holiday.first(holiday_date: absence[:absence_date]).nil? && shift[:includes_holidays]
        available_employees = available_employees.select { |e| e[:works_holidays] }
      end

      # matching type?
      available_employees = available_employees.find_all { |e| shift.type_id == e.type_id }

      # reject for absences
      available_employees = available_employees.reject do |e|
        # can't replace himself
        e.id == absence.absence_id || \
        # current replacement
        e.id == absence.replacement_id || \
        # already replacing someone else
        e.shift_replacements.any? { |r| r.absence_date == absence.absence_date } || \
        # absent on that day
        e.shift_absences.any? { |a| a.absence_date == absence.absence_date }
      end

      # available on that time?
      available_employees = available_employees.find_all { |employee| employee_availability_matches_shift(employee, shift, date_to_week_day(absence[:absence_date])) }
    end

    # show employees with more free time first
    available_employees.sort_by { |e| e[:max_weekly_hours] + (e[:max_weekly_hours] - employee_assigned_hours(e)) }
  end
end
