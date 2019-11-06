class AlertController < ApplicationController
  get '/list', auth: :user do
    erb :alert_list, locals: { menu: [:alerts],
                               alerts_count: Alert.count,
                               breadcrumb: [{ url: '/', name: 'Inicio' },
                                            { url: '', name: 'Alertas activas' }],
                               alerts: Alert.all }
  end

  get '/cleanup', auth: :user do
    alerts_to_clear = Alert.where(alert_type: 'needs_replacement')
    alerts_to_clear.each { |a| check_alert_needs_replacement(a.shift) }
    redirect build_success_url '/alert/list', params[:redir]
  end

  get '/client/:id', auth: :user do
    client = Client[params[:id]]
    redirect '/404' if client.nil?

    erb :alert_list, locals: { menu: [:alerts],
                               alerts_count: Alert.count,
                               breadcrumb: [{ url: '/', name: 'Inicio' },
                                            { url: '/alert/list', name: 'Alertas activas' },
                                            { url: '', name: client.name }],
                               alerts: Alert.where { { client_id: client[:id] } | { location_id: client.locations.map { |l| l.id } } | { shift_id: client.shifts.map { |s| s.id } } } }
  end

  get '/employee/:id', auth: :user do
    employee = Employee[params[:id]]
    redirect '/404' if employee.nil?

    erb :alert_list, locals: { menu: [:alerts],
                               alerts_count: Alert.count,
                               breadcrumb: [{ url: '/', name: 'Inicio' },
                                            { url: '/alert/list', name: 'Alertas activas' },
                                            { url: '', name: employee.name }],
                               alerts: Alert.where(employee_id: employee[:id]) }
  end
end
