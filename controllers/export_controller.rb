class ExportController < ApplicationController
  get '/custom', auth: :user do
    erb :export_custom, locals: { menu: [:export],
                                  breadcrumb: [{ url: '/', name: 'Inicio' },
                                               { url: '/control_panel/list', name: 'Panel de control' },
                                               { url: '', name: 'Exportado a medida' }] }
  end

  post '/custom/client', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      # avoid nils
      params[:client_fields] = params[:client_fields].to_a
      params[:client_location_fields] = params[:client_location_fields].to_a
      params[:client_shift_fields] = params[:client_shift_fields].to_a
      params[:client_extra_fields] = params[:client_extra_fields].to_a

      csv_array << export_client_row_titles

      Client.all.each do |client|
        row_client = export_client_row(client)

        if client.locations.nil? || client.locations.empty?
          row_location = params[:client_location_fields].map { |_f| '' }
          row_shift = params[:client_shift_fields].map { |_f| '' }
          row_extra = export_client_extras(nil, nil)
          csv_array << row_client + row_location + row_shift + row_extra
          next
        end

        client.locations.each do |location|
          row_location = export_client_row_location(location)

          if location.shifts.nil? || location.shifts.empty?
            row_shift = params[:client_shift_fields].map { |_f| '' }
            row_extra = export_client_extras(location, nil)
            csv_array << row_client + row_location + row_shift + row_extra
            next
          end

          location.shifts.each do |shift|
            row_shift = export_client_row_shift(shift)

            if params[:client_extra_fields].nil? || params[:client_extra_fields].empty?
              csv_array << row_client + row_location + row_shift
              next
            end

            row_extra = export_client_extras(location, shift)
            csv_array << row_client + row_location + row_shift + row_extra
          end
        end
      end
    end

    content_type 'application/csv'
    attachment 'clients_export.csv'
    csv_data
  end

  post '/custom/employee', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      # avoid nils
      params[:employee_fields] = params[:employee_fields].to_a
      params[:employee_shift_fields] = params[:employee_shift_fields].to_a
      params[:employee_extra_fields] = params[:employee_extra_fields].to_a

      csv_array << export_employee_row_titles

      Employee.all.each do |employee|
        row_client = export_employee_row(employee)

        if employee.shifts.empty?
          row_shift = params[:employee_shift_fields].map { |_f| '' }
          row_extra = export_employee_extras(employee, nil)
          csv_array << row_client + row_shift + row_extra
          next
        end

        employee.shifts.each do |shift|
          row_shift = export_employee_row_shift(shift)

          if params[:employee_extra_fields].nil? || params[:employee_extra_fields].empty?
            csv_array << row_client + row_shift
            next
          end

          row_extra = export_employee_extras(employee, shift)
          csv_array << row_client + row_shift + row_extra
        end
      end
    end

    content_type 'application/csv'
    attachment 'clients_export.csv'
    csv_data
  end

  get '/clients', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      csv_array << client_import_fields.map { |_k, v| v }
      Client.each do |client|
        client_csv = []
        client_import_fields.each do |k, v|
          client_csv << if client[k].is_a?(TrueClass) || client[k].is_a?(FalseClass)
                          client[k] ? 'Sí' : 'No'
                        else
                          client[k]
                        end
        end
        csv_array << client_csv
      end
    end

    content_type 'application/csv'
    attachment 'clients.csv'
    csv_data
  end

  get '/employees', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      csv_array << employee_import_fields.map { |_k, v| v }
      Employee.each do |employee|
        employee_csv = []
        employee_import_fields.each do |k, v|
          employee_csv << if employee[k].is_a?(TrueClass) || employee[k].is_a?(FalseClass)
                            employee[k] ? 'Sí' : 'No'
                          else
                            employee[k]
                          end
        end
        csv_array << employee_csv
      end
    end

    content_type 'application/csv'
    attachment 'employees.csv'
    csv_data
  end

  post '/employee_updates', auth: :user do
    start_date = params[:start_date]
    end_date = params[:end_date]

    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      csv_array << ['Empleado', 'Fecha', 'Novedad', 'Cliente', 'Estación', 'Hora inicio', 'Hora fin', 'Detalle']
      Employee.sort_by { |e| e[:last_name] }.each do |employee|
        csv_data = []
        employee.shift_absences_dataset.where(absence_date: (start_date..end_date)).each do |a|
          absence_type = 'Ausencia'
          absence_type = 'Ausencia justificada' if !a.employee_absence.nil? && a.employee_absence[:justified]
          csv_data << [employee.sortable_name, a[:absence_date], absence_type, a.client[:name], a.location.full_name, a.shift[:start_time], a.shift[:end_time], a[:reason]]
        end
        employee.shift_replacements_dataset.where(absence_date: (start_date..end_date)).each do |r|
          csv_data << [employee.sortable_name, r[:absence_date], 'Suplencia', r.client[:name], r.location.full_name, r.shift[:start_time], r.shift[:end_time], "Cubre ausencia de #{r.absent_employee.name}"]
        end
        employee.overtime_dataset.where(date: (start_date..end_date)).each do |o|
          csv_data << [employee.sortable_name, o[:date], 'Horas extras', o.client[:name], o.location.full_name, o[:start_time], o[:end_time], o[:reason]]
        end
        employee.late_arrivals_dataset.where(date: (start_date..end_date)).each do |la|
          csv_data << [employee.sortable_name, la[:date], 'Llegada tarde', la.client[:name], la.location.full_name, la.shift[:start_time], la.shift[:end_time], la[:reason]]
        end
        employee.shift_backups_dataset.where(date: (start_date..end_date)).each do |sb|
          csv_data << [employee.sortable_name, sb[:date], 'Refuerzo', sb.client[:name], sb.location.full_name, sb[:start_time], sb[:end_time], sb[:reason]]
        end
        csv_data.sort_by { |row| row[1] }.each { |row| csv_array << row }
      end
    end

    content_type 'application/csv'
    attachment 'employee_updates.csv'
    csv_data
  end

  get '/locations', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      csv_array << location_import_fields.map { |_k, v| v }
      Location.each do |location|
        location_csv = []
        location_import_fields.each do |k, v|
          location_csv << if location[k].is_a?(TrueClass) || location[k].is_a?(FalseClass)
                            location[k] ? 'Sí' : 'No'
                          elsif k == :parent_id
                            location[:parent_id].nil? ? '' : location.parent[:name]
                          elsif k == :end_date
                            location[:end_date] == Date.new(2099, 1, 1) ? '' : location[:end_date]
                          else
                            location[k]
                          end
        end
        csv_array << location_csv
      end
    end

    content_type 'application/csv'
    attachment 'locations.csv'
    csv_data
  end

  get '/shifts', auth: :user do
    csv_data = CSV.generate(force_quotes: true) do |csv_array|
      csv_array << ['Cliente', 'Estación de trabajo', 'Turno', 'Empleado']
      Shift.order(:client_id, :location_id).each do |shift|
        csv_array << [shift.client.name, shift.location.full_name, shift_readable_dates(shift), shift.employee.nil? ? '' : shift.employee.full_name]
      end
    end

    content_type 'application/csv'
    attachment 'shifts.csv'
    csv_data
  end
end
