class LocationController < ApplicationController
  get '/new/:client_id/?:parent_id?', auth: :location_new do
    redirect '/404' if Client[params[:client_id]].nil?
    redirect '/404' if params[:parent_id] && Location[params[:parent_id]].nil?
    client = Client[params[:client_id]]
    if params[:parent_id].nil?
      breadcrumbs = location_breadcrumbs(nil)
      breadcrumbs << { url: '', name: 'Nueva estación de trabajo' }
      erb :location_new, locals: { menu: [:client],
                                   breadcrumb: breadcrumbs,
                                   client: client }
    else
      breadcrumbs = location_breadcrumbs(Location[params[:parent_id]], true)
      breadcrumbs << { url: '', name: 'Nueva estación de trabajo' }
      erb :location_new, locals: { menu: %i[client location],
                                   breadcrumb: breadcrumbs,
                                   location: Location[params[:parent_id]],
                                   client: client }
    end
  end

  get '/edit/:location_id', auth: :location_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?

    Location.columns.each { |key| params[key] = location[key] }

    breadcrumbs = location_breadcrumbs(location)
    erb :location_new, locals: { menu: [:client],
                                 breadcrumb: breadcrumbs,
                                 location: location }
  end

  post '/edit/:location_id', auth: :location_new do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?

    location = location_setup(location, params, location.parent)

    if location.valid?
      DB.transaction do
        location.save

        action_log = action_log_for_location(location, 'Se <strong>modificó</strong> una estación de trabajo')
        action_log.save
      end

      redirect build_success_url("/location/#{location[:id]}", params[:redir])
    else
      redirect build_error_url("/location/edit/#{location.id}", params, location.errors)
    end
  end

  post '/new/:client_id/?:parent_id?', auth: :location_new do
    redirect '/404' if Client[params[:client_id]].nil?
    redirect '/404' if params[:parent_id] && Location[params[:parent_id]].nil?

    location = Location.new

    parent_location = if params[:parent_id].nil?
                        Location.new
                      else
                        Location[params[:parent_id]]
                      end

    location = location_setup(location, params, parent_location)
    location.parent_id = params[:parent_id] || nil

    if location.valid?
      DB.transaction do
        location.save

        action_log = action_log_for_location(location, 'Se <strong>agregó</strong> una nueva estación de trabajo')
        action_log.save
      end

      if user_matches_type(:location_contract_edit)
        redirect build_success_url("/location/contract/#{location[:id]}", params[:redir])
      else
        redirect build_success_url("/location/#{location[:id]}", params[:redir])
      end
    else
      location_url = "/location/new/#{params[:client_id]}" + (params[:parent_id].nil? ? '' : "/#{params[:parent_id]}")
      redirect build_error_url(location_url, params, location.errors)
    end
  end

  get '/contract/:location_id', auth: :location_contract_edit do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?

    breadcrumbs = location_breadcrumbs(location, true)
    breadcrumbs << { url: '', name: 'Alertas de contrato' }
    erb :location_contract, locals: { menu: %i[client location],
                                      breadcrumb: breadcrumbs,
                                      location: location }
  end

  post '/contract/:location_id', auth: :location_contract_edit do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?

    location.min_employees = params[:min_employees]
    location.supervisor_needed = params[:supervisor_needed] || false
    location.end_date = params[:end_date]

    if location.valid?
      DB.transaction do
        location.save
        action_log = action_log_for_location(location, 'Se <strong>modificó</strong> el contrato de una estación de trabajo')
        action_log.save
        check_alert_contract_needs_atention(location)
      end

      redirect build_success_url("/location/#{params[:location_id]}", params[:redir])
    else
      redirect build_error_url("/location/contract/#{params[:location_id]}", params, location.errors)
    end
  end

  get '/archive/:id', auth: :location_archive do
    location = Location[params[:id]]
    redirect '/404' if location.nil?

    DB.transaction do
      action_log = action_log_for_location(location, 'Se <strong>archivó</strong> una estación')
      action_log.save

      location[:archived] = true
      location.shifts.each { |shift| archive_shift(shift) }

      location.children.each do |l|
        l[:archived] = true
        l.save
        l.shifts.each { |shift| archive_shift(shift) }
      end
      location.save
    end

    if location.parent.nil?
      redirect build_success_url("/client/#{location.client[:id]}", params[:redir])
    else
      redirect build_success_url("/location/#{location.parent[:id]}", params[:redir])
    end
  end

  get '/unarchive/:id', auth: :location_unarchive do
    location = Location[params[:id]]
    redirect '/404' if location.nil?

    DB.transaction do
      action_log = action_log_for_location(location, 'Se <strong>reactivó</strong> una estación')
      action_log.save

      location[:archived] = false
      location.children.each do |l|
        l[:archived] = false
        l.save
      end
      location.save
    end

    redirect build_success_url("/location/#{location[:id]}", params[:redir])
  end

  get '/delete/:id', auth: :location_archive do
    location = Location[params[:id]]
    redirect '/404' if location.nil?
    client = location.client

    DB.transaction do
      if location.shifts.to_a.count.zero? && location.children.count.zero?
        action_log = action_log_for_location(location, 'Se <strong>borró</strong> una estación de trabajo')
        action_log.save

        location.delete

        if location[:parent_id].nil?
          redirect build_success_url("/client/#{client[:id]}", params[:redir])
        else
          redirect build_success_url("/location/#{location[:parent_id]}", params[:redir])
        end
      else
        redirect "/location/archive/#{location[:id]}"
      end
    end
  end

  get '/:id', auth: :user do
    redirect '/404' if Location[params[:id]].nil?
    location = Location[params[:id]]
    breadcrumbs = location_breadcrumbs(location)

    erb :location_single, locals: { menu: %i[client location],
                                    breadcrumb: breadcrumbs,
                                    location: location }
  end

end
