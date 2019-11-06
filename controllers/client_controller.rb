class ClientController < ApplicationController
  get '/list/?:current_page?', provides: %i[html json], auth: :user do
    if request.accept.any? { |a| a.to_s =~ /json/ }
      Client.order(:name).map do |client|
        {
          id: client.id,
          name: client.name,
          archived: client[:archived]
        }
      end.to_json
    else
      current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
      page_size = 20

      clients = client_filters(Client, params)
      clients = clients.order(:name).paginate(current_page, page_size)

      redirect "/client/list/#{clients.page_count}?#{build_query_string(%w[current_page id])}" if current_page > clients.page_count

      erb :client_list, locals: { menu: [:client],
                                  breadcrumb: [{ url: '/', name: 'Inicio' },
                                               { url: '/client/list', name: 'Clientes' }],
                                  clients: clients }
    end
  end

  get '/edit/:id', auth: :client_new do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    Client.columns.each { |key| params[key] = client[key] }

    params[:iva_perception] = client[:iva_perception] ? 'on' : ''
    params[:iibb_perception] = client[:iibb_perception] ? 'on' : ''

    erb :client_new, locals: { menu: [:client],
                               breadcrumb: [{ url: '/', name: 'Inicio' },
                                            { url: '/client/list', name: 'Clientes' },
                                            { url: '', name: client.name }],
                               client: client }
  end

  post '/edit/:id', auth: :client_new do
    client = Client[params[:id]]
    client = client_setup(client, params)
    client[:cuit] = 'invalid' unless validate_cuit(client[:cuit])

    if client.valid?
      DB.transaction do
        client.save

        action_log = action_log_for_client(client, 'Se <strong>modificó</strong> un cliente')
        action_log.save
      end
      redirect build_success_url("/client/#{client.id}", params[:redir])
    else
      redirect build_error_url("/client/edit/#{client.id}", params, client.errors)
    end
  end

  get '/new', auth: :client_new do
    erb :client_new, locals: { menu: [:client],
                               breadcrumb: [{ url: '/', name: 'Inicio' },
                                            { url: '/client/list', name: 'Clientes' },
                                            { url: '', name: 'Nuevo cliente' }] }
  end

  post '/logo/:id', auth: :client_logo do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    uploaded_logo = GD2::Image.import(params[:logo][:tempfile].path)

    # crop if needed
    if uploaded_logo.aspect > 1.to_f
      logo = GD2::Image::TrueColor.new(uploaded_logo.width, uploaded_logo.width)
      height_diff = (uploaded_logo.width - uploaded_logo.height) / 2
      logo.copy_from(uploaded_logo, 0, height_diff, 0, 0, uploaded_logo.width, uploaded_logo.height)
      (0..uploaded_logo.width).each { |x| (0..height_diff).each { |y| logo[x, y] = GD2::Color::WHITE } }
      (0..uploaded_logo.width).each { |x| ((uploaded_logo.height + height_diff)..logo.height).each { |y| logo[x, y] = GD2::Color::WHITE } }
    elsif uploaded_logo.aspect < 1.to_f
      logo = GD2::Image::TrueColor.new(uploaded_logo.height, uploaded_logo.height)
      width_diff = (uploaded_logo.height - uploaded_logo.width) / 2
      logo.copy_from(uploaded_logo, width_diff, 0, 0, 0, uploaded_logo.width, uploaded_logo.height)
      (0..width_diff).each { |x| (0..uploaded_logo.height).each { |y| logo[x, y] = GD2::Color::WHITE } }
      ((uploaded_logo.width + width_diff)..logo.width).each { |x| (0..uploaded_logo.height).each { |y| logo[x, y] = GD2::Color::WHITE } }
    else
      logo = uploaded_logo
    end

    # delete it if it already exists
    FileUtils.rm "./public/logos/#{client.id}.jpg", force: true

    logo
      .resize(150, 150, true)
      .export("./public/logos/#{client.id}.jpg", quality: 95)

    redirect build_success_url("/client/#{client.id}", params[:redir])
  end

  post '/new', auth: :client_new do
    client = Client.new
    client = client_setup(client, params)
    client[:cuit] = 'invalid' unless validate_cuit(client[:cuit])

    if client.valid?
      DB.transaction do
        client.save

        action_log = action_log_for_client(client, 'Se <strong>agregó</strong> un nuevo cliente')
        action_log.save
      end
      redirect build_success_url("/client/#{client.id}", params[:redir])
    else
      redirect build_error_url('/client/new', params, client.errors)
    end
  end

  get '/archive/:id', auth: :client_archive do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    DB.transaction do
      action_log = action_log_for_client(client, 'Se <strong>archivó</strong> un cliente')
      action_log.save

      client[:archived] = true
      client.locations.each do |l|
        l[:archived] = true
        l.save
      end
      client.shifts.each do |s|
        archive_shift(s, false)
      end
      client.save
    end

    redirect build_success_url('/client/list', params[:redir])
  end

  get '/unarchive/:id', auth: :client_unarchive do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    DB.transaction do
      action_log = action_log_for_client(client, 'Se <strong>reactivó</strong> un cliente')
      action_log.save

      client[:archived] = false
      client.locations.each do |l|
        l[:archived] = false
        l.save
      end
      client.save
    end

    redirect build_success_url("/client/#{client[:id]}", params[:redir])
  end

  get '/delete/:id', auth: :client_archive do
    client = Client[params[:id]]
    redirect '/404' if client.nil?
    locations = Location.where(client_id: client[:id]).where(parent_id: nil)

    DB.transaction do
      if locations.count.zero? && !client.nil?
        action_log = action_log_for_client(client, 'Se <strong>borró</strong> un cliente')
        action_log.save

        client.delete
        redirect build_success_url('/client/list', params[:redir])
      else
        redirect "/client/archive/#{client[:id]}"
      end
    end
  end

  get '/:id/?:current_page?', auth: :user do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    if request.accept.any? { |a| a.to_s =~ /json/ }
      {
        id: client[:id],
        name: client[:name],
        archived: client[:archived],
        locations: client.locations.map do |location|
                     {
                       id: location[:id],
                       name: location.full_name,
                       archived: location[:archived]
                     }
                   end
      }.to_json
    else
      current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
      page_size = 20

      locations = location_filters(Location.where(client_id: client.id).where(parent_id: nil), params)
      locations = locations.order(:name).paginate(current_page, page_size)

      redirect "/client/#{client[:id]}/#{locations.page_count}?#{build_query_string(['current_page', 'id'])}" if current_page > locations.page_count

      shifts = Shift.where(location_id: locations.map { |l| l.id }).distinct(:employee_id).exclude(employee_id: nil)
      employees = Employee.where(id: shifts.map(&:employee_id))

      erb :client_single, locals: { menu: [:client],
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/client/list', name: 'Clientes' },
                                                 { url: '', name: client.name }],
                                    client: client,
                                    locations: locations,
                                    employees: employees }
    end
  end
end
