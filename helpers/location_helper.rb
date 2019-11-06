module LocationHelper
  def location_import_fields
    {
      client_id: 'Nombre cliente',
      name: 'Nombre estación de trabajo',
      address_street: 'Dirección (calle)',
      address_street_between: 'Dirección (entre calles)',
      address_number: 'Dirección (nro)',
      address_extra: 'Dirección (extra)',
      address_cp: 'Dirección (CP)',
      address_city: 'Dirección (ciudad)',
      address_province: 'Dirección (provincia)',
      address_country: 'Dirección (país)',
      parent_id: 'Nombre de estación padre',
      min_employees: 'Mínimo de empleados',
      supervisor_needed: 'Se necesita Supervisor',
      end_date: 'Fecha de finalización'
    }
  end

  def location_filters(locations, params)
    locations = locations.where(archived: false) unless params[:show_archived] == '1'

    if params[:filter_by_name] == 'on' && !params[:name].empty?
      params[:name].split.each do |name_filter|
        name_search = "%#{name_filter}%".to_s
        locations = locations.where{ Sequel.ilike(:name, name_search) }
      end
    end

    locations = locations.where(address_city: params[:address_city]) if params[:filter_by_city] == 'on'
    locations = locations.where(address_province: params[:address_province]) if params[:filter_by_province] == 'on'
    locations = locations.where(address_country: params[:address_country]) if params[:filter_by_country] == 'on'

    locations.order(:name)
  end

  def location_setup(location, params, parent_location = nil)
    Location.columns.each { |key| location[key] = params[key] if !params[key].nil? && key != :id }

    location[:supervisor_needed] ||= (!params[:supervisor_needed].nil? && params[:supervisor_needed] =~ /si|sí|on/i)

    parent_location = Location.new if parent_location.nil?
    Location.columns.each { |key| location[key] ||= parent_location[key] if key != :id }

    location
  end
end
