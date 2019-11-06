class ShiftController < ApplicationController
  post '/assign', auth: :shift_assign do
    shift = Shift[params[:shift_id]]
    redirect '/404' if shift.nil?
    employee = Employee[params[:employee_id]]
    redirect "/shift/#{shift.id}" if employee.nil? || !shift.employee_id.nil?

    replacement_collisions = employee
                             .shift_replacements
                             .find_all { |replacement| replacement.absence_date >= [Date.today, shift.start_date].max && shift_matching_dates(shift, replacement.absence_date, replacement.absence_date).any? }

    if shift.valid?
      DB.transaction do
        shift[:employee_id] = employee[:id]
        shift[:start_date] = Date.today
        shift.save

        action_log = action_log_for_shift(shift, "#{link_employee(shift.employee_id)} fue <strong>asignado</strong> a un turno de trabajo")
        action_log.save

        replacement_collisions.each do |replacement|
          action_log = action_log_for_absence(replacement, "#{link_employee(replacement.replacement_id)} fue <strong>removido</strong> de una suplencia")
          action_log.save

          replacement[:replacement_id] = nil
          replacement.save
        end

        check_alert_contract_needs_atention(shift.location)
        check_alert_2shifts_jointed(employee)
        check_alert_too_many_hours(employee)
        check_alert_empty_shift(shift)
        check_availability_hours_with_shifts(employee)
      end
      redirect "/location/#{shift[:location_id]}"
    else
      redirect build_error_url("/shift/edit/#{params[:shift_id]}", params, shift.errors)
    end
  end

  get '/unassign/:shift_id', auth: :shift_unassign do
    shift = Shift[params[:shift_id]]
    redirect '/404' if shift.nil?
    redirect "/location/#{shift[:location_id]}" if shift[:employee_id].nil?
    employee = Employee[shift[:employee_id]]
    redirect '/404' if employee.nil?

    if shift.valid?
      DB.transaction do
        action_log = action_log_for_shift(shift, "#{link_employee(shift.employee_id)} fue <strong>removido</strong> de un turno de trabajo")
        action_log.save

        # add a new shift to replace the old one (to avoid losing its history)
        archive_shift(shift, true)

        check_alert_2shifts_jointed(employee)
        check_alert_too_many_hours(employee)
        check_availability_hours_with_shifts(employee)
      end

      if params[:redir].nil?
        redirect build_success_url("/location/#{shift[:location_id]}", params[:redir])
      else
        redirect params[:redir]
      end
    else
      redirect build_error_url("/shift/edit/#{params[:shift_id]}", params, shift.errors)
    end
  end

  get '/new/:location_id', auth: :shift_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?
    client = location.client
    job_types = JobType.all

    breadcrumb = location_breadcrumbs(location, true)
    breadcrumb << { url: '', name: 'Nuevo turno de trabajo' }

    erb :shift_new, locals: { menu: %i[client location shift],
                              breadcrumb: breadcrumb,
                              location: location,
                              job_types: job_types,
                              client: client }
  end

  post '/new/:location_id', auth: :shift_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?
    client = location.client
    amount = params[:amount].nil? ? 1 : params[:amount].to_i

    shifts = []
    (1..amount).each do
      shift = Shift.new
      shift_setup(shift, params)

      shift[:client_id] = client[:id]
      shift[:location_id] = location[:id]
      shift, shift_new_work_hours = get_shift_work_hours(shift, params)

      shifts << [shift, shift_new_work_hours]
    end

    if shifts.all? { |shift, work_hours| shift.valid? && work_hours.all?(&:valid?) }
      DB.transaction do
        shifts.each do |shift, work_hours|
          action_log = action_log_for_shift(shift, 'Se <strong>agregó</strong> un turno de trabajo')
          action_log.save

          shift.save

          work_hours.each do |wh|
            wh[:shift_id] = shift[:id]
            wh.save
          end

          check_alert_contract_needs_atention(location)
          check_alert_empty_shift(shift)
        end
      end
      redirect build_success_url("/location/#{params[:location_id]}", params[:redir])
    else
      redirect build_error_url("/shift/new/#{params[:location_id]}", params, shifts[0][0].errors)
    end
  end

  get '/edit/:id', auth: :shift_new do
    shift = Shift[params[:id]]
    redirect '/404' if shift.nil?

    Shift.columns.each do |key|
      params[key] = shift[key]
      params[key] = 'on' if shift[key].is_a?(TrueClass)
    end
    params[:holidays] = shift[:includes_holidays] ? '1' : '0'
    params[:end_date] = shift[:end_date] == Date.new(2099,1,1) ? nil : shift[:end_date]
    params[:type] = shift.type[:type]

    location = shift.location
    client = shift.client
    job_types = JobType.all

    breadcrumb = location_breadcrumbs(location, true)
    breadcrumb << { url: '', name: "Editando turno ##{shift.id}" }

    erb :shift_new, locals: { menu: %i[client location shift],
                              breadcrumb: breadcrumb,
                              shift: shift,
                              location: location,
                              job_types: job_types,
                              client: client }
  end

  post '/edit/:id', auth: :shift_new do
    shift = Shift[params[:id]]
    redirect '/404' if shift.nil?

    shift = shift_setup(shift, params)
    shift, shift_new_work_hours = get_shift_work_hours(shift, params)

    if shift.valid? && shift_new_work_hours.all?(&:valid?)
      DB.transaction do
        shift.save

        shift.work_hours.each { |swh| swh.delete unless shift_new_work_hours.include? swh }
        shift_new_work_hours.each(&:save)

        action_log = action_log_for_shift(shift, 'Se <strong>modificó</strong> un turno de trabajo')
        action_log.save

        check_alert_contract_needs_atention(shift.location)
        check_alert_empty_shift(shift)
        check_alert_invalid_type(shift)
        check_availability_hours_with_shifts(shift.employee) unless shift.employee.nil?
      end

      redirect build_success_url("/location/#{shift[:location_id]}", params[:redir])
    else
      redirect build_error_url("/shift/edit/#{params[:id]}", params, shift.errors)
    end
  end

  get '/copy/:shift_id', auth: :shift_new do
    old_shift = Shift[params[:shift_id]]
    redirect '/404' if old_shift.nil?

    new_shift = shift_setup(Shift.new, old_shift)
    new_shift[:employee_id] = nil
    new_shift[:archived] = false
    new_shift[:start_date] = Date.today unless new_shift[:start_date] > Date.today
    new_shift[:end_date] = nil
    new_shift, new_shift_work_hours = get_shift_work_hours(new_shift, old_shift)

    if new_shift.valid? && new_shift_work_hours.all?(&:valid?)
      DB.transaction do
        action_log = action_log_for_shift(new_shift, 'Se <strong>agregó</strong> un turno de trabajo')
        action_log.save

        new_shift.save
        new_shift_work_hours.each { |swh| swh[:shift_id] = new_shift[:id] }.each(&:save)

        check_alert_contract_needs_atention(new_shift.location)
        check_alert_empty_shift(new_shift)
      end
    end

    redirect build_success_url("/location/#{old_shift[:location_id]}", params[:redir])
  end

  get '/delete/:shift_id', auth: :shift_delete do
    shift = Shift[params[:shift_id]]
    redirect '/404' if shift.nil?
    location = shift.location
    employee = shift.employee

    DB.transaction do
      action_log = action_log_for_shift(shift, 'Se <strong>borró</strong> un turno de trabajo')
      action_log.save

      if employee.nil?
        shift.delete
      else
        archive_shift(shift, false)
      end

      check_alert_contract_needs_atention(location)
      unless employee.nil?
        check_alert_2shifts_jointed(employee)
        check_alert_too_many_hours(employee)
      end
    end

    redirect build_success_url("/location/#{location[:id]}", params[:redir])
  end

  get '/:shift_id', auth: :user do
    shift = Shift[params[:shift_id]]
    redirect '/404' if shift.nil?
    location = shift.location
    client = location.client

    filtered_employees = employee_filters(Employee, params)
    available_employees = available_employees_for_shift(shift, filtered_employees)

    breadcrumb = location_breadcrumbs(location, true)
    breadcrumb << { url: '', name: "Turno \##{shift.id}" }

    erb :shift_single, locals: { menu: %i[client location shift],
                                 breadcrumb: breadcrumb,
                                 location: location,
                                 client: client,
                                 shift: shift,
                                 job_types: JobType.all,
                                 available_employees: available_employees }
  end
end
