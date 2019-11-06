class AbsenceController < ApplicationController
  get '/list', auth: :user do
    absences = ShiftAbsence
               .where { absence_date > (Date.today - 30) }
               .where(replacement_id: nil)
               .group_and_count(:absence_id)

    erb :absence_list, locals: { menu: [:absence],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/absence/list', name: 'Ausencias' }],
                                 absences: absences }
  end

  get_or_post '/merge/:absence_id_left/:absence_id_right', auth: :absence_new do
    absence_id_left = EmployeeAbsence[params[:absence_id_left]]
    absence_id_right = EmployeeAbsence[params[:absence_id_right]]
    redirect '/404' if absence_id_left.nil? || absence_id_right.nil?
    employee = absence_id_left.employee

    if absence_id_left[:absence_end_date] + 1 == absence_id_right[:absence_start_date]
      DB.transaction do
        absence_id_left[:absence_end_date] = absence_id_right[:absence_end_date]
        absence_id_right.shift_absences.each do |abs|
          abs[:employee_absence_id] = absence_id_left[:id]
          abs.save
        end
        absence_id_left.save
        absence_id_right.delete
      end
      redirect build_success_url("/employee/#{employee.id}", params[:redir])
    else
      redirect build_error_url(build_success_url("/employee/#{employee.id}", params[:redir]), params, {})
    end
  end

  get '/cancel/:employee_absence_id', auth: :absence_cancel do
    employee_absence = EmployeeAbsence[params[:employee_absence_id]]
    redirect '/404' if employee_absence.nil?

    DB.transaction do
      employee_absence.shift_absences.each do |absence|
        action_log = action_log_for_absence(absence, "#{link_employee(absence.absence_id)} <strong>cancela</strong> la ausencia a un turno")
        action_log.save

        employee_to_check = absence.replacement_employee
        shift_to_check = absence.shift

        absence.delete

        check_alert_needs_replacement(shift_to_check)
        check_availability_hours_with_replacements(employee_to_check)
      end

      action_log = action_log_for_employee_absence(employee_absence, "#{link_employee(employee_absence.employee_id)} <strong>cancela</strong> un período de ausencia")
      action_log.save

      employee_absence.delete
    end

    redirect build_success_url("/employee/#{employee_absence[:employee_id]}", params[:redir])
  end

  get_or_post '/assign', auth: :absence_assign do
    employee = Employee[params[:employee_id]]
    redirect '/404' if employee.nil?

    if !params[:absences].nil? && params[:absences].any?
      absences = params[:absences]
                 .map { |absence_id| ShiftAbsence[absence_id] }
    # .reject { |a| a.absence_date < Date.today }
    elsif params.any? { |p| p[0] =~ /absence_.*/ }
      absences = params
                 .find_all { |p| p[0] =~ /absence_.*/ }
                 .map { |p| ShiftAbsence[p[0][8..-1]] }
      # .reject { |a| a.absence_date < Date.today }
    end

    redirect build_success_url("/employee/#{employee.id}", params[:redir]) if absences.nil? || absences == []

    unless params[:replacement].nil?
      # prevents multiple assignations on simultaneous requests
      if params[:replacement] == '0' || available_employees_for_absences(absences).any? { |e| e.id == params[:replacement].to_i }
        DB.transaction do
          absences.each do |absence|
            if params[:replacement] == '0'
              action_log = action_log_for_absence(absence, "#{link_employee(absence.replacement_id)} fue <strong>removido</strong> de una suplencia")
              replacement = Employee[absence.replacement_id]
              absence.replacement_id = nil
            else
              absence.replacement_id = params[:replacement].to_i
              replacement = Employee[absence.replacement_id]
              action_log = action_log_for_absence(absence, "#{link_employee(replacement.id)} fue <strong>asignado</strong> a una suplencia")
            end

            check_alert_2shifts_jointed(replacement) unless replacement.nil?
            check_alert_too_many_hours(replacement) unless replacement.nil?
            check_alert_needs_replacement(absence.shift)

            absence.save
            action_log.save
          end

          check_availability_hours_with_replacements(employee)
        end
        redirect build_success_url("/employee/#{employee[:id]}", params[:redir])
      end
    end

    filtered_employees = employee_filters(Employee, params)
    available_employees = available_employees_for_absences(absences, filtered_employees)

    erb :absence_assign, locals: { menu: [:employee],
                                   breadcrumb: [{ url: '/', name: 'Inicio' },
                                                { url: '/employee/list', name: 'Empleados' },
                                                { url: "/employee/#{employee.id}", name: employee.full_name },
                                                { url: '', name: 'Ausencia' }],
                                   available_employees: available_employees,
                                   absences: absences }
  end

  get '/unassign/:absence_id', auth: :absence_unassign do
    absence = ShiftAbsence[params[:absence_id]]
    redirect '/404' if absence.nil?

    removed_replacement = absence[:replacement_id]
    DB.transaction do
      action_log = action_log_for_absence(absence, "#{link_employee(absence[:replacement_id])} fue <strong>removido</strong> de una suplencia")
      action_log.save

      absence[:replacement_id] = nil
      absence.save

      replacement_employee = Employee[removed_replacement]
      check_alert_2shifts_jointed(replacement_employee)
      check_alert_too_many_hours(replacement_employee) unless replacement_employee.nil?
      check_alert_needs_replacement(absence.shift)
      check_availability_hours_with_replacements(absence.employee)
    end

    redirect build_success_url("/employee/#{removed_replacement}", params[:redir])
  end

  post '/license/new', auth: :absence_license_new do
    employee_absence = EmployeeAbsence[params[:absence_id]]
    redirect '/404' if employee_absence.nil?

    employee = employee_absence.employee
    upload_file = params[:file]

    file = EmployeeFile.new
    file[:date_time] = DateTime.now
    file[:uploader_id] = @user.id
    file[:employee_id] = employee.id
    file[:file_type_id] = EmployeeFileType.where(type: 'Parte Médico').first[:id]
    file[:description] = "Archivo asociado a ausencia de #{employee_absence[:absence_start_date]} a #{employee_absence[:absence_end_date]}"
    file[:path] = "/upload/#{employee.id}/#{upload_file[:filename]}"

    employee_absence_file = EmployeeAbsenceFile.new
    EmployeeAbsenceFile.columns.each { |key| employee_absence_file[key] = params[key] if !params[key].nil? && key != :id }
    employee_absence_file[:employee_id] = employee[:id]
    employee_absence_file[:employee_absence_id] = employee_absence[:id]
    employee_absence_file[:employee_file_id] = 0

    if file.valid? && employee_absence_file.valid?
      FileUtils.mkdir("./public/upload/#{employee[:id]}") unless File.directory? "./public/upload/#{employee[:id]}"
      FileUtils.mv upload_file[:tempfile].path, "./public/upload/#{employee[:id]}/#{upload_file[:filename]}"

      DB.transaction do
        file.save

        employee_absence_file[:employee_file_id] = file[:id]
        employee_absence_file.save

        unless params[:mark_justified].nil?
          employee_absence[:justified] = true
          employee_absence.save
        end

        action_log = action_log_for_employee(employee, "Se <strong>agregó</strong> el archivo #{upload_file[:filename]} a su fichero")
        action_log.save
      end

      redirect build_success_url("/employee/#{employee.id}", params[:redir])
    else
      errors = file.errors.merge(employee_absence_file.errors)
      redirect build_error_url("/employee/#{employee.id}", params, errors)
    end
  end

  get '/new/:employee_id', auth: :absence_new do
    employee = Employee[params[:employee_id]]
    redirect '/404' if employee.nil?

    erb :absence_new, locals: { menu: [:employee],
                                breadcrumb: [{ url: '/', name: 'Inicio' },
                                             { url: '/employee/list', name: 'Empleados' },
                                             { url: "/employee/#{employee.id}", name: employee.full_name },
                                             { url: '', name: 'Ausencia' }],
                                employee: employee }
  end

  post '/new/:employee_id', provides: %i[html json], auth: :absence_new do
    employee = Employee[params[:employee_id]]
    redirect '/404' if employee.nil?

    absences = []
    replacements = []
    errors = {}

    if params[:reason].nil? || params[:reason].empty?
      errors[:reason] = ['No puede estar vacío']
    end

    if params[:daterange].nil? || params[:daterange].empty?
      errors[:daterange] = ['No puede estar vacío']
      start_date = end_date = Date.today
    else
      (start_date, end_date) = params[:daterange].split(' - ')
    end
    start_date = Date.parse(start_date) unless start_date.is_a? Date
    end_date = Date.parse(end_date) unless end_date.is_a? Date

    if errors.empty?
      # create shift absences in advance
      employee.shifts.each do |shift|
        dates = shift_matching_dates(shift, start_date, end_date)
        next if dates.empty?

        dates.each do |date|
          absence = ShiftAbsence.new
          absence[:client_id] = shift[:client_id]
          absence[:location_id] = shift[:location_id]
          absence[:absence_id] = employee[:id]
          absence[:shift_id] = shift[:id]
          absence[:absence_date] = date
          absence[:reason] = params[:reason]

          if absence.valid?
            absences << absence
          else
            error_text = "Colisiona con una ausencia ya cargada (#{absence[:absence_date]})"
            if errors[:daterange].is_a?(Array)
              errors[:daterange] << error_text
            else
              errors[:daterange] = [error_text]
            end
          end
        end
      end

      # load replacements active set for those days
      employee.shift_replacements.each do |replacement|
        if replacement.absence_date >= start_date && replacement.absence_date <= end_date
          replacements << replacement
        end
      end
    end

    if errors.empty?
      DB.transaction do
        # The employee won't be available on this period
        employee_absence = EmployeeAbsence.new
        employee_absence.employee_id = employee.id
        employee_absence.absence_start_date = start_date
        employee_absence.absence_end_date = end_date
        employee_absence.notice_date = params[:notice_date]
        employee_absence.reason = params[:reason]
        employee_absence.save

        # Save shift absences already set
        if absences.count > 0
          absences.each do |absence|
            absence.employee_absence_id = employee_absence.id

            action_log = action_log_for_absence(absence, "#{link_employee(absence.absence_id)} <strong>anuncia</strong> una ausencia")
            action_log.save
            absence.save

            # This will probably trigger every time
            check_alert_needs_replacement(absence.shift)
          end
        end

        # This employee won't be able to replace another one during this period
        if replacements.count > 0
          replacements.each do |replacement|
            action_log = action_log_for_absence(replacement, "#{link_employee(replacement.replacement_id)} fue <strong>removido</strong> de una suplencia")
            action_log.save

            replacement.replacement_id = nil
            replacement.save

            # Add this absence for the next step
            absences << replacement
          end
        end
      end

      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'ok', url: "/absence/assign?employee_id=#{employee.id}&#{absences.map { |a| "absences[]=#{a.id}" }.join('&')}&#{replacements.map { |a| "absences[]=#{a.id}" }.join('&')}" }.to_json
      else
        redirect build_success_url("/employee/#{employee.id}", params[:redir])
      end
    elsif request.accept.any? { |a| a.to_s =~ /json/ }
      { response: 'error', url: build_error_url("/absence/new/#{employee.id}", params, errors) }.to_json
    else
      redirect build_error_url("/absence/new/#{employee.id}", params, errors)
    end
  end

  post '/edit/:employee_absence_id', provides: %i[html json], auth: :absence_new do
    employee_absence = EmployeeAbsence[params[:employee_absence_id]]
    redirect '/404' if employee_absence.nil?

    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    new_absence_dates = []
    new_absences = []
    absence_dates_to_delete = []
    absences_to_delete = []
    errors = {}

    if end_date > employee_absence[:absence_end_date]
      ((employee_absence[:absence_end_date] + 1)..end_date).each { |date| new_absence_dates << date }
    elsif end_date < employee_absence[:absence_end_date]
      ((end_date + 1)..employee_absence[:absence_end_date]).each { |date| absence_dates_to_delete << date }
    end

    if start_date < employee_absence[:absence_start_date]
      (start_date..(employee_absence[:absence_start_date] - 1)).each { |date| new_absence_dates << date }
    elsif start_date > employee_absence[:absence_start_date]
      (employee_absence[:absence_start_date]..(start_date - 1)).each { |date| absence_dates_to_delete << date }
    end

    if new_absence_dates.count > 0
      employee_absence.employee.shifts.each do |shift|
        next if shift[:archived]

        shift_dates = new_absence_dates.find_all { |date| !shift_matching_dates(shift, date, date).empty? }
        next if shift_dates.empty?

        shift_dates.each do |date|
          absence = ShiftAbsence.new
          absence[:client_id] = shift[:client_id]
          absence[:location_id] = shift[:location_id]
          absence[:absence_id] = employee_absence.employee[:id]
          absence[:shift_id] = shift[:id]
          absence[:absence_date] = date
          absence[:reason] = params[:reason]
          absence[:employee_absence_id] = employee_absence[:id]

          if absence.valid?
            new_absences << absence
          else
            error_text = "Colisiona con una ausencia ya cargada (#{absence[:absence_date]})"
            if errors[:daterange].is_a?(Array)
              errors[:daterange] << error_text
            else
              errors[:daterange] = [error_text]
            end
          end
        end
      end
    end

    employee_absence
      .shift_absences
      .find_all { |absence| absence_dates_to_delete.include?(absence[:absence_date]) }
      .each { |absence| absences_to_delete << absence }

    if errors.nil? || errors.empty?
      DB.transaction do
        # Update current shift absences reason
        if employee_absence[:reason] != params[:reason]
          employee_absence.shift_absences.each do |absence|
            absence[:reason] = params[:reason]
            absence.save if absence.valid?
          end
        end

        # Update absence dates
        employee_absence[:absence_start_date] = params[:start_date]
        employee_absence[:absence_end_date] = params[:end_date]
        employee_absence[:reason] = params[:reason]
        employee_absence.save

        # Save new shift absences
        new_absences.each do |absence|
          absence.save

          action_log = action_log_for_absence(absence, "#{link_employee(absence[:absence_id])} <strong>anuncia</strong> una ausencia")
          action_log.save

          # This will probably trigger every time
          check_alert_needs_replacement(absence.shift)
        end

        # Delete unneeded ones
        absences_to_delete.each do |absence|
          action_log = action_log_for_absence(absence, "#{link_employee(absence[:absence_id])} <strong>cancela</strong> la ausencia a un turno")
          action_log.save

          absence.delete

          check_alert_needs_replacement(absence.shift)
          check_availability_hours_with_replacements(absence.absent_employee)
        end

        # This employee won't be able to replace another one during this period
        employee_absence.employee.shift_replacements.each do |replacement|
          next unless replacement[:absence_date].between?(start_date, end_date)

          action_log = action_log_for_absence(replacement, "#{link_employee(replacement.replacement_id)} fue <strong>removido</strong> de una suplencia")
          action_log.save

          replacement[:replacement_id] = nil
          replacement.save
        end
      end

      absence_assign_url = "/absence/assign?employee_id=#{employee_absence.employee[:id]}&#{new_absences.map { |a| "absences[]=#{a[:id]}" }.join('&')}"
      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'ok', url: absence_assign_url }.to_json
      else
        redirect build_success_url absence_assign_url, params[:redir]
      end
    else
      error_url = build_error_url((build_success_url "/employee/#{employee_absence.employee[:id]}", params[:redir]), params, errors)
      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'error', url: error_url }.to_json
      else
        redirect error_url
      end
    end
  end
end