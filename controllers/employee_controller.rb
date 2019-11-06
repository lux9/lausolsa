class EmployeeController < ApplicationController
  get '/list/?:current_page?', provides: %i[html json], auth: :user do
    if request.accept.any? { |a| a.to_s =~ /json/ }
      Employee.order(:last_name, :first_name).map { |employee| { id: employee.id, file_n: employee.file_number, name: employee.name } }.to_json
    else
      current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
      page_size = 20

      employees = employee_filters(Employee, params)
      employees = employees.order(:last_name, :first_name).paginate(current_page, page_size)

      redirect "/employee/list/#{employees.page_count}?#{build_query_string(['current_page', 'id'])}" if current_page > employees.page_count

      erb :employee_list, locals: { menu: [:employee],
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '', name: 'Empleados' }],
                                    employees: employees,
                                    job_types: JobType.all }
    end
  end

  get '/edit/:id', auth: :employee_new do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    Employee.columns.each { |key| params[key] = employee[key] }

    params[:type] = employee.type[:type]
    params[:worker_union] = employee[:worker_union] ? 'on' : ''
    params[:works_holidays] = employee[:works_holidays] ? 'on' : ''

    job_types = JobType.all
    erb :employee_new, locals: { menu: [:employee],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/employee/list', name: 'Empleados' },
                                              { url: '', name: employee.name }],
                                 employee: employee,
                                 job_types: job_types }
  end

  post '/edit/:id', auth: :employee_new do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    employee = employee_setup(employee, params)

    job_type = JobType.where(type: params[:type]).first
    employee[:type_id] = job_type[:id] unless job_type.nil?
    employee[:cuit] = 'invalid' unless validate_cuit(employee[:cuit])

    if employee.valid?
      DB.transaction do
        employee.save

        action_log = action_log_for_employee(employee, 'Se <strong>modificó</strong> un empleado')
        action_log.save

        employee.shifts.each { |s| check_alert_invalid_type(s) }
      end

      redirect "/employee/#{employee.id}"
    else
      redirect build_error_url("/employee/edit/#{employee.id}", params, employee.errors)
    end
  end

  get '/new', auth: :employee_new do
    job_types = JobType.all
    erb :employee_new, locals: { menu: [:employee],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/employee/list', name: 'Empleados' },
                                              { url: '', name: 'Nuevo empleado' }],
                                 job_types: job_types }
  end

  post '/new', auth: :employee_new do
    employee = Employee.new
    employee = employee_setup(employee, params)

    job_type = JobType.where(type: params[:type]).first
    employee[:type_id] = job_type[:id] unless job_type.nil?
    employee[:cuit] = 'invalid' unless validate_cuit(employee[:cuit])
    employee[:work_hours] = '{}' # TODO: backwards compatibility, remove later

    if employee.valid?
      DB.transaction do
        employee.save

        available_hours = employee_default_available_hours(employee)
        available_hours.values.each(&:save)

        action_log = action_log_for_employee(employee, 'Se <strong>agregó</strong> un nuevo empleado')
        action_log.save
      end

      redirect build_success_url("/employee/#{employee.id}", params[:redir])
    else
      redirect build_error_url('/employee/new', params, employee.errors)
    end
  end

  post '/avatar/:id', auth: :employee_avatar do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    avatar = GD2::Image.import(params[:avatar][:tempfile].path)

    # crop if needed
    if avatar.aspect > 1.to_f
      new_width = new_height = avatar.height
      start_x = (avatar.width - avatar.height) / 2
      avatar.crop!(start_x, 0, new_width, new_height)
    elsif avatar.aspect < 1.to_f
      new_width = new_height = avatar.width
      start_y = (avatar.height - avatar.width) / 2
      avatar.crop!(0, start_y, new_width, new_height)
    end

    # delete it if it already exists
    FileUtils.rm "./public/avatars/#{employee.id}.jpg", force: true

    avatar
      .resize(150, 150, true)
      .export("./public/avatars/#{employee.id}.jpg", quality: 95)

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  get '/late_arrival/new/:employee_id', auth: :late_arrival_new do
    employee = Employee[params[:employee_id]]
    redirect '/404' if employee.nil?

    erb :employee_late_arrival_new, locals: { menu: [:employee],
                                              breadcrumb: [{ url: '/', name: 'Inicio' },
                                                           { url: '/employee/list', name: 'Empleados' },
                                                           { url: "/employee/#{employee.id}", name: employee.full_name },
                                                           { url: '', name: 'Nueva llegada tarde' }],
                                              employee: employee }
  end

  post '/late_arrival/new/:employee_id', provides: %i[html json], auth: :late_arrival_new do
    employee = Employee[params[:employee_id]]
    shift = Shift[params[:shift_id]]
    redirect '/404' if employee.nil? || shift.nil?

    late_arrival = ShiftLateArrival.new
    late_arrival.employee_id = employee[:id]
    late_arrival.shift_id = shift[:id]
    late_arrival.location_id = shift.location[:id]
    late_arrival.client_id = shift.client[:id]
    late_arrival.date = params[:date]
    late_arrival.reason = params[:reason]

    if late_arrival.valid?
      DB.transaction do
        late_arrival.save

        action_log = action_log_for_employee(employee, "Se <strong>cargó</strong> una llegada tarde el #{params[:date]} al turno ##{shift[:id]} de #{shift.client[:name]}")
        action_log.save
      end

      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'ok', url: "/employee/#{employee.id}" }.to_json
      else
        redirect build_success_url("/employee/#{employee.id}", params[:redir])
      end
    elsif request.accept.any? { |a| a.to_s =~ /json/ }
      { response: 'error', url: build_error_url("/employee/late_arrival/new/#{employee.id}", params, late_arrival.errors) }.to_json
    else
      redirect build_error_url("/employee/late_arrival/new/#{employee.id}", params, late_arrival.errors)
    end
  end

  get '/late_arrival/delete/:id', auth: :late_arrival_delete do
    late_arrival = ShiftLateArrival[params[:id]]
    redirect '/404' if late_arrival.nil?

    employee = late_arrival.employee
    late_arrival.delete

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  get '/overtime/:id', auth: :overtime_new do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    erb :employee_overtime_new, locals: { menu: [:employee],
                                          breadcrumb: [{ url: '/', name: 'Inicio' },
                                                       { url: '/employee/list', name: 'Empleados' },
                                                       { url: "/employee/#{employee.id}", name: employee.full_name },
                                                       { url: '', name: 'Horas extras' }],
                                          employee: employee }
  end

  post '/overtime/:id', auth: :overtime_new do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    overtime = EmployeeOvertime.new
    EmployeeOvertime.columns.each { |key| overtime[key] = params[key] if key != :id }
    overtime[:employee_id] = employee[:id]
    overtime[:hours] = time_difference(overtime[:start_time], overtime[:end_time]) / 3600.0
    overtime[:double_pay] = (!params[:double_pay].nil? && params[:double_pay] =~ /si|sí|on/i)
    overtime[:night_time] = (!params[:night_time].nil? && params[:night_time] =~ /si|sí|on/i)

    shift_that_date = employee.shifts.find { |s| !shift_matching_dates(s, overtime[:date], overtime[:date]).empty? }
    if shift_that_date.nil?
      shifts_during_that_time = false
    else
      shifts_during_that_time = (shift_that_date[:start_time] <= overtime[:start_time] && shift_that_date[:end_time] > overtime[:start_time]) || \
                                (overtime[:start_time] <= shift_that_date[:start_time] && shift_that_date[:start_time] < overtime[:end_time])
    end

    absent_that_date = employee.shift_absences.any? { |a| a.absence_date == overtime[:date] }
    replacements_during_that_time = employee.shift_replacements.any? { |r| r.absence_date == overtime[:date] && (r.shift[:end_time] > overtime[:start_time] || r.shift[:start_time] <= overtime[:end_time]) }

    if absent_that_date || shifts_during_that_time || replacements_during_that_time
      overtime[:date] = '2001-01-01' # FIXME: collision with a valid date
    end

    if overtime.valid?
      DB.transaction do
        overtime.save

        action_log = action_log_for_employee(employee, "Se <strong>cargaron</strong> #{overtime.hours} horas extras")
        action_log.save
      end
      redirect build_success_url("/employee/#{employee.id}", params[:redir])
    else
      redirect build_error_url("/employee/overtime/#{employee.id}", params, overtime.errors)
    end
  end

  get '/overtime/delete/:id', auth: :overtime_delete do
    overtime = EmployeeOvertime[params[:id]]
    redirect '/404' if overtime.nil?

    employee = overtime.employee
    overtime.delete

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  get '/file/:id', auth: :user do
    file = EmployeeFile[params[:id]]
    redirect '/404' if file.nil?

    file_object = File.join('./public', file.path)
    send_file(file_object, disposition: 'attachment', filename: File.basename(file.path))
  end

  post '/file/:id', auth: :employee_file_new do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    upload_file = params[:file]
    description = params[:description]
    redirect build_success_url("/employee/#{employee.id}?invalid=1", params[:redir]) if description.nil? || description.empty? || upload_file.nil? || upload_file.empty?

    file = EmployeeFile.new
    file.date_time = DateTime.now
    file.uploader_id = @user.id
    file.employee_id = employee.id
    file.file_type_id = params[:type]
    file.description = description
    file.path = "/upload/#{employee.id}/#{upload_file[:filename]}"

    if file.valid?
      FileUtils.mkdir("./public/upload/#{employee.id}") unless File.directory? "./public/upload/#{employee.id}"
      FileUtils.mv upload_file[:tempfile].path, "./public/upload/#{employee.id}/#{upload_file[:filename]}"
      DB.transaction do
        file.save

        action_log = action_log_for_employee(employee, "Se <strong>agregó</strong> el archivo #{upload_file[:filename]} a su fichero")
        action_log.save
      end
    end

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  get '/file/delete/:id', auth: :employee_file_delete do
    file = EmployeeFile[params[:id]]
    redirect '/404' if file.nil?

    employee = file.employee
    file.delete
    FileUtils.rm "./public#{file.path}", force: true

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  post '/edit_availability/:id', auth: :employee_availability do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    current_ah = employee.available_hours.to_a
    %w[monday tuesday wednesday thursday friday saturday sunday].each do |day|
      ah_day = current_ah.find { |ah| ah[:day_of_week] == day }

      if ah_day.nil?
        ah_day = EmployeeAvailableHours.new
        ah_day[:employee_id] = employee[:id]
        ah_day[:day_of_week] = day
        current_ah << ah_day
      end

      (0..23).each do |h|
        ah_day["hour_#{h}".to_sym] = params["#{day}_#{h}".to_sym] == 'on' ? 1.0 : 0.0
      end
    end

    if current_ah.all?(&:valid?)
      DB.transaction do
        current_ah.each(&:save)
        action_log_for_employee(employee, '<strong>Modificó</strong> su horario de disponibilidad')
        check_availability_hours_with_shifts(employee)
        check_availability_hours_with_replacements(employee)
      end
    end

    redirect build_success_url("/employee/#{employee.id}", params[:redir])
  end

  get '/archive/:id', auth: :employee_archive do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    DB.transaction do
      action_log = action_log_for_employee(employee, 'Se <strong>archivó</strong> un empleado')
      action_log.save

      employee[:archived] = true
      employee.shifts.each do |s|
        archive_shift(s, true)
      end
      employee.shift_replacements.find_all { |r| r[:absence_date] > Date.today }.each do |r|
        r[:replacement_id] = nil
        r.save
        check_alert_needs_replacement(r.shift)
      end
      employee.save
    end

    redirect build_success_url('/employee/list', params[:redir])
  end

  get '/unarchive/:id', auth: :employee_unarchive do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    DB.transaction do
      action_log = action_log_for_employee(employee, 'Se <strong>reactivó</strong> un cliente')
      action_log.save

      employee[:archived] = false
      employee.save
    end

    redirect build_success_url("/employee/#{employee[:id]}", params[:redir])
  end

  get '/delete/:id', auth: :employee_archive do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    employee_empty = employee.shifts.to_a.count.zero? && \
                     employee.employee_absences.to_a.count.zero? && \
                     employee.shift_absences.to_a.count.zero? && \
                     employee.shift_replacements.to_a.count.zero?

    DB.transaction do
      action_log = action_log_for_employee(employee, 'Se <strong>borró</strong> un empleado')
      action_log.save

      if employee_empty
        employee.delete
      else
        employee[:archived] = true
        employee.save
      end
    end

    redirect build_success_url('/employee/list', params[:redir])
  end

  get '/:id', auth: :user do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    if request.accept.any? { |a| a.to_s =~ /json/ }
      {
        id: employee.id,
        file_n: employee.file_number,
        name: employee.name,
        shifts: employee.shifts.map do |shift|
                  {
                    id: shift.id,
                    client: shift.client.name,
                    location: shift.location.name,
                    dates: shift_readable_dates(shift)
                  }
                end
      }.to_json
    else
      erb :employee_single, locals: { menu: [:employee],
                                      breadcrumb: [{ url: '/', name: 'Inicio' },
                                                   { url: '/employee/list', name: 'Empleados' },
                                                   { url: '', name: employee.full_name }],
                                      employee: employee,
                                      employee_file_types: EmployeeFileType.all,
                                      documents: Document.where(type: 'employee') }
    end
  end
end
