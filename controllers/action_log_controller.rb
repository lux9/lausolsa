class ActionLogController < ApplicationController
  get '/recent/?:current_page?', auth: :user do
    current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
    page_size = 20
    log_lines = ActionLog.reverse_order(:id).paginate(current_page, page_size)
    redirect "/action_log/recent/#{log_lines.page_count}" if current_page > log_lines.page_count

    erb :action_log_list, locals: { menu: [:log],
                                    alerts_count: Alert.count,
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/control_panel/list', name: 'Panel de control' },
                                                 { url: '/action_log/recent', name: 'Registro de acciones' }],
                                    log_lines: log_lines }
  end

  get '/client/:client_id/?:current_page?', auth: :user do
    client = Client[params[:client_id]]
    redirect '/404' if client.nil?

    current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
    page_size = 20
    log_lines = ActionLog.where(client_id: client.id).reverse_order(:id).paginate(current_page, page_size)
    redirect "/action_log/client/#{client.id}/#{log_lines.page_count}" if current_page > log_lines.page_count

    erb :action_log_list, locals: { menu: [:log],
                                    alerts_count: Alert.count,
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/control_panel/list', name: 'Panel de control' },
                                                 { url: '/action_log/recent', name: 'Registro de acciones' },
                                                 { url: "/action_log/client/#{client.id}", name: "Cliente #{client.name}" }],
                                    log_lines: log_lines }
  end

  get '/employee/:employee_id/?:current_page?', auth: :user do
    employee = Employee[params[:employee_id]]
    redirect '/404' if employee.nil?

    current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
    page_size = 20
    log_lines = ActionLog.where(employee_id: employee.id).reverse_order(:id).paginate(current_page, page_size)
    redirect "/action_log/client/#{employee.id}/#{log_lines.page_count}" if current_page > log_lines.page_count

    erb :action_log_list, locals: { menu: [:log],
                                    alerts_count: Alert.count,
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/control_panel/list', name: 'Panel de control' },
                                                 { url: '/action_log/recent', name: 'Registro de acciones' },
                                                 { url: "/action_log/employee/#{employee.id}", name: "Empleado #{employee.name}" }],
                                    log_lines: log_lines }
  end

  get '/location/:location_id/?:current_page?', auth: :user do
    location = Location[params[:location_id]]
    redirect '/404' if location.nil?

    current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
    page_size = 20
    log_lines = ActionLog.where(location_id: location.id).reverse_order(:id).paginate(current_page, page_size)
    redirect "/action_log/location/#{location.id}/#{log_lines.page_count}" if current_page > log_lines.page_count

    erb :action_log_list, locals: { menu: [:log],
                                    alerts_count: Alert.count,
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/control_panel/list', name: 'Panel de control' },
                                                 { url: '/action_log/recent', name: 'Registro de acciones' },
                                                 { url: "/action_log/client/#{location.client.id}", name: "Cliente #{location.client.name}" },
                                                 { url: "/action_log/location/#{location.id}", name: "Estación #{location.full_name}" }],
                                    log_lines: log_lines }
  end
end
