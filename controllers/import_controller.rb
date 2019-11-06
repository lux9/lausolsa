class ImportController < ApplicationController
  get '/', auth: :user do
    erb :import_form, locals: { menu: [:import],
                                breadcrumb: [{ url: '/', name: 'Inicio' },
                                             { url: '/control_panel/list', name: 'Panel de control' },
                                             { url: '/import', name: 'Importador' }] }
  end

  post '/clients', auth: :user do
    redirect '/import' if params[:file].nil?

    clients = []
    file_url = params[:file][:tempfile].path
    redirect '/import' if file_url.nil? || !File.exist?(file_url)

    xlsx = Roo::Spreadsheet.open file_url
    xlsx.sheet(0).each(client_import_fields) do |row|
      next if row[:name] == 'Nombre'

      client = Client.new
      client = client_setup(client, row)

      client[:cuit] = 'invalid' unless validate_cuit(client[:cuit])

      client[:iva_perception] = nil
      client[:iva_perception] = true if row[:iva_perception] =~ /si|sí/i
      client[:iva_perception] = false if row[:iva_perception] =~ /no/i

      client[:iibb_perception] = nil
      client[:iibb_perception] = true if row[:iibb_perception] =~ /si|sí/i
      client[:iibb_perception] = false if row[:iibb_perception] =~ /no/i

      client.save if client.valid?
      clients << client
    end

    erb :import_client_status, locals: { menu: [:import],
                                         breadcrumb: [{ url: '/', name: 'Inicio' },
                                                      { url: '/control_panel/list', name: 'Panel de control' },
                                                      { url: '/import', name: 'Importador' },
                                                      { url: '', name: 'Clientes' }],
                                         clients: clients }
  end

  post '/employees', auth: :user do
    redirect '/import' if params[:file].nil?

    employees = []
    file_url = params[:file][:tempfile].path
    redirect '/import' if file_url.nil? || !File.exist?(file_url)

    xlsx = Roo::Spreadsheet.open file_url
    xlsx.sheet(0).parse(employee_import_fields) do |row|
      next if row[:first_name] == 'Nombre'

      employee = Employee.new
      employee = employee_setup(employee, row)

      job_type = JobType.where(type: row[:type_id]).first
      employee[:type_id] = job_type[:id] unless job_type.nil?
      employee[:cuit] = 'invalid' unless validate_cuit(employee[:cuit])

      employee[:worker_union] = nil
      employee[:worker_union] = true if row[:worker_union] =~ /si|sí/i
      employee[:worker_union] = false if row[:worker_union] =~ /no/i

      employee[:works_holidays] = nil
      employee[:works_holidays] = true if row[:works_holidays] =~ /si|sí/i
      employee[:works_holidays] = false if row[:works_holidays] =~ /no/i

      employee[:max_weekly_hours] = row[:max_weekly_hours].to_i

      employee.save if employee.valid?
      employees << employee
    end

    erb :import_employee_status, locals: { menu: [:import],
                                           breadcrumb: [{ url: '/', name: 'Inicio' },
                                                        { url: '/control_panel/list', name: 'Panel de control' },
                                                        { url: '/import', name: 'Importador' },
                                                        { url: '', name: 'Empleados' }],
                                           employees: employees }
  end

  post '/locations', auth: :user do
    redirect '/import' if params[:file].nil?

    locations = []
    file_url = params[:file][:tempfile].path
    redirect '/import' if file_url.nil? || !File.exist?(file_url)

    xlsx = Roo::Spreadsheet.open file_url
    xlsx.sheet(0).each(location_import_fields) do |row|
      next if row[:name] == 'Nombre estación de trabajo'

      location = Location.new
      location = location_setup(location, row)

      client = Client.where(name: row[:client_id]).first
      location[:client_id] = client.nil? ? nil : client[:id]

      unless row[:parent_id].nil? || row[:parent_id] == '' || client.nil?
        parent_location = Location.where(name: row[:parent_id]).where(client_id: client[:id]).first
        location[:parent_id] = nil
        location[:parent_id] = parent_location[:id] unless parent_location.nil?
      end

      location[:supervisor_needed] = nil
      location[:supervisor_needed] = true if row[:supervisor_needed] =~ /si|sí/i
      location[:supervisor_needed] = false if row[:supervisor_needed] =~ /no/i

      location.save if location.valid?
      locations << location
    end

    erb :import_location_status, locals: { menu: [:import],
                                           breadcrumb: [{ url: '/', name: 'Inicio' },
                                                        { url: '/control_panel/list', name: 'Panel de control' },
                                                        { url: '/import', name: 'Importador' },
                                                        { url: '', name: 'Estaciones de trabajo' }],
                                           locations: locations }
  end
end
