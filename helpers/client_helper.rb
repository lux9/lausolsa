module ClientHelper
  def client_import_fields
    {
      name: 'Nombre',
      cuit: 'CUIT',
      address_street: 'Dirección (calle)',
      address_street_between: 'Dirección (entre calles)',
      address_number: 'Dirección (nro)',
      address_extra: 'Dirección (extra)',
      address_cp: 'Dirección (CP)',
      address_city: 'Dirección (ciudad)',
      address_province: 'Dirección (provincia)',
      address_country: 'Dirección (país)',
      tax_condition: 'Condición Impositiva',
      iibb: 'Ingresos Brutos',
      iva_perception: 'Percepción IVA',
      iibb_perception: 'Percepción IIBB'
    }
  end

  def client_extra_fields
    {
      shift_absence: 'Ausencias a turnos',
      shift_replacement: 'Suplencias de turnos',
      shift_backup: 'Refuerzos solicitados'
    }
  end

  def client_filters(clients, params)
    clients = clients.where(archived: false) unless params[:show_archived] == '1'

    unless params[:starting_letter].nil?
      name_search = "#{params[:starting_letter]}%"
      clients = clients.where{ Sequel.ilike(:name, name_search) }
    end

    if params[:filter_by_name] == 'on' && !params[:name].empty?
      params[:name].split.each do |name_filter|
        name_search = "%#{name_filter}%".to_s
        clients = clients.where{ Sequel.ilike(:name, name_search) }
      end
    end

    clients = clients.where(address_city: params[:address_city]) if params[:filter_by_city] == 'on'
    clients = clients.where(address_province: params[:address_province]) if params[:filter_by_province] == 'on'
    clients = clients.where(address_country: params[:address_country]) if params[:filter_by_country] == 'on'

    clients
  end

  def client_setup(client, params)
    Client.columns.each { |key| client[key] = params[key] if !params[key].nil? && key != :id }

    client[:iva_perception] = !!(!params[:iva_perception].nil? && params[:iva_perception] =~ /si|sí|on/i)
    client[:iibb_perception] = !!(!params[:iibb_perception].nil? && params[:iibb_perception] =~ /si|sí|on/i)

    client
  end
end
