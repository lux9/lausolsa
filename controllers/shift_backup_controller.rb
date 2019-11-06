class ShiftBackupController < ApplicationController
  post '/assign', auth: :shift_backup_assign do
    shift_backup = ShiftBackup[params[:shift_backup_id]]
    redirect '/404' if shift_backup.nil?
    employee = Employee[params[:employee_id]]
    redirect "/shift_backup/#{shift_backup.id}" if employee.nil? || !shift_backup[:employee_id].nil?

    replacement_collisions = employee
                             .shift_replacements
                             .find_all do |replacement|
                               replacement[:absence_date] == shift_backup[:date] &&
                                 replacement[:start_time] < shift_backup[:end_time] &&
                                 replacement[:end_time] > shift_backup[:start_time]
                             end

    DB.transaction do
      shift_backup[:employee_id] = employee[:id]
      shift_backup.save

      action_log = action_log_for_employee(employee, "#{link_employee(shift_backup[:employee_id])} fue <strong>asignado</strong> al pedido de refuerzo ##{shift_backup[:request_id]}")
      action_log.save

      replacement_collisions.each do |replacement|
        action_log = action_log_for_absence(replacement, "#{link_employee(replacement.replacement_id)} fue <strong>removido</strong> de una suplencia")
        action_log.save

        replacement.replacement_id = nil
        replacement.save
      end

      check_alert_too_many_hours(employee)
      check_alert_location_with_missing_backups(shift_backup.location)
    end

    redirect build_success_url("/location/#{shift_backup[:location_id]}", params[:redir])
  end

  get '/unassign/:shift_backup_id', auth: :shift_backup_unassign do
    shift_backup = ShiftBackup[params[:shift_backup_id]]
    redirect '/404' if shift_backup.nil?
    employee = shift_backup.employee
    redirect "/location/#{shift_backup.location[:id]}" if employee.nil?

    DB.transaction do
      shift_backup[:employee_id] = nil
      shift_backup.save

      action_log = action_log_for_employee(employee, "#{link_employee(employee[:id])} fue <strong>asignado</strong> a un pedido de refuerzo")
      action_log.save

      check_alert_too_many_hours(employee)
      check_alert_location_with_missing_backups(shift_backup.location)
    end

    redirect build_success_url("/location/#{shift_backup[:location_id]}", params[:redir])
  end

  get '/new/:location_id', auth: :shift_backup_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?
    client = Client[location[:client_id]]
    job_types = JobType.all

    breadcrumb = location_breadcrumbs(location, true)
    breadcrumb << { url: '', name: 'Nuevo pedido de refuerzo' }

    erb :shift_backup_new, locals: { menu: %i[client location shift],
                                     breadcrumb: breadcrumb,
                                     location: location,
                                     job_types: job_types,
                                     client: client }
  end

  post '/new/:location_id', provides: %i[html json], auth: :shift_backup_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?
    client = Client[location[:client_id]]

    shift_backup = ShiftBackup.new
    shift_backup = shift_backup_setup(shift_backup, params)
    shift_backup[:client_id] = client[:id]
    shift_backup[:location_id] = location[:id]
    shift_backup, shift_backup_work_hours = get_shift_backup_work_hours(shift_backup, params)

    if shift_backup.valid? && shift_backup_work_hours.all?(&:valid?)
      DB.transaction do
        action_log = action_log_for_client(client, "Se <strong>agregó</strong> un pedido de refuerzo ##{shift_backup[:request_id]}")
        action_log.save

        shift_backup.save

        shift_backup_work_hours.each do |swh|
          swh[:shift_backup_id] = shift_backup[:id]
          swh.save
        end
      end
      check_alert_location_with_missing_backups(shift_backup.location)
      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'ok', url: "/shift_backup/#{shift_backup[:id]}" }.to_json
      else
        redirect build_success_url("/shift_backup/#{shift_backup[:id]}", params[:redir])
      end
    else
      error_url = build_error_url("/shift_backup/new/#{params[:location_id]}", params, shift_backup.errors)
      if request.accept.any? { |a| a.to_s =~ /json/ }
        { response: 'error', url: error_url }.to_json
      else
        redirect error_url
      end
    end
  end

  get '/delete/:shift_backup_id', auth: :shift_backup_delete do
    shift_backup = ShiftBackup[params[:shift_backup_id]]
    redirect '/404' if shift_backup.nil?
    client = shift_backup.client
    location = shift_backup.location

    DB.transaction do
      action_log = action_log_for_client(client, "Se <strong>borró</strong> el pedido de refuerzo ##{shift_backup[:request_id]}")
      action_log.save

      shift_backup.work_hours.each(&:delete)
      shift_backup.delete
    end

    check_alert_location_with_missing_backups(location)
    redirect build_success_url("/location/#{location[:id]}", params[:redir])
  end

  get '/:shift_backup_id', auth: :user do
    shift_backup = ShiftBackup[params[:shift_backup_id]]
    redirect '/404' if shift_backup.nil?
    location = shift_backup.location
    client = location.client

    filtered_employees = employee_filters(Employee, params)
    available_employees = available_employees_for_shift_backup(shift_backup, filtered_employees)
    is_holiday = (Holiday.where(holiday_date: shift_backup[:date]).count > 0)

    breadcrumb = location_breadcrumbs(location, true)
    breadcrumb << { url: '', name: "Refuerzo \##{shift_backup[:request_id]}" }

    erb :shift_backup_single, locals: { menu: %i[client location],
                                        breadcrumb: breadcrumb,
                                        location: location,
                                        client: client,
                                        shift_backup: shift_backup,
                                        is_holiday: is_holiday,
                                        job_types: JobType.all,
                                        available_employees: available_employees }
  end
end
