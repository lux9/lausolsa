class ControlPanelController < ApplicationController
  get '/list', auth: :user do
    job_types = JobType.all
    file_types = EmployeeFileType.all
    users = User.all
    user_roles = UserRole.all

    erb :control_panel_list, locals: { menu: [],
                                       breadcrumb: [{ url: '/', name: 'Inicio' },
                                                    { url: '', name: 'Panel de control' }],
                                       job_types: job_types,
                                       file_types: file_types,
                                       users: users,
                                       user_roles: user_roles }
  end

  get '/roles/new', auth: :roles_new do
    erb :user_role_new, locals: { menu: [],
                                  breadcrumb: [{ url: '/', name: 'Inicio' },
                                               { url: '/control_panel/list', name: 'Panel de control' },
                                               { url: '/control_panel/roles/new', name: 'Nuevo set de permisos' }] }
  end

  post '/roles/new', auth: :roles_new do
    user_role = UserRole.new
    user_role[:name] = params[:name]
    user_role[:privileges] = available_privileges.each_with_object({}) do |privilege, privileges|
      privileges[privilege[0]] = true if params[privilege[0]] == 'on'
    end.to_json.to_s

    if user_role.valid?
      user_role.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/roles/new', params, user_role.errors
    end
  end

  get '/roles/edit/:id', auth: :roles_new do
    user_role = UserRole[params[:id]]
    redirect '/404' if user_role.nil?

    params[:name] = user_role[:name]
    em_role_privileges_to_params(user_role[:privileges]).to_a.each { |p| params[p[0].to_sym] = p[1] }

    erb :user_role_new, locals: { menu: [],
                                  breadcrumb: [{ url: '/', name: 'Inicio' },
                                               { url: '/control_panel/list', name: 'Panel de control' },
                                               { url: '/control_panel/roles/new', name: 'Nuevo set de permisos' }],
                                  user_role: user_role }
  end

  post '/roles/edit/:id', auth: :roles_new do
    user_role = UserRole[params[:id]]
    redirect '/404' if user_role.nil?

    user_role[:name] = params[:name]
    user_role[:privileges] = available_privileges.each_with_object({}) do |privilege, privileges|
      privileges[privilege[0]] = true if params[privilege[0]] == 'on'
    end.to_json.to_s

    if user_role.valid?
      user_role.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url "/control_panel/roles/edit/#{user_role[:id]}", params, user_role.errors
    end
  end

  get '/delete_file_type/:id', auth: :file_types_delete do
    file_type = EmployeeFileType[params[:id]]
    file_type.delete unless file_type.nil?
    redirect build_success_url '/control_panel/list', params[:redir]
  end

  get '/delete_job_type/:id', auth: :job_types_delete do
    job_type = JobType[params[:id]]
    job_type.delete unless job_type.nil?
    redirect build_success_url '/control_panel/list', params[:redir]
  end

  get '/delete_user/:id', auth: :users_delete do
    user = User[params[:id]]
    user.delete unless user.nil?
    redirect build_success_url '/control_panel/list', params[:redir]
  end

  post '/new_user', auth: :users_new do
    new_user = User.new
    new_user.email = params[:email]
    new_user.password = params[:password]
    new_user.password_confirmation = params[:password]
    new_user.first_name = params[:first_name]
    new_user.last_name = params[:last_name]

    if new_user.valid?
      new_user.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/list', params, new_user.errors
    end
  end

  post '/update_user_password', auth: :users_password do
    new_user = User[params[:id]]
    redirect build_error_url('/control_panel/list', params, []) if new_user.nil?

    new_user.password = params[:password]
    new_user.password_confirmation = params[:password]

    if new_user.valid?
      new_user.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/list', params, new_user.errors
    end
  end

  get_or_post '/update_user_role/:user_id/:role_id', auth: :users_role do
    user = User[params[:user_id]]
    redirect build_error_url('/control_panel/list', params, []) if user.nil?

    role = UserRole[params[:role_id]]
    redirect build_error_url('/control_panel/list', params, []) if role.nil?

    user[:role_id] = role[:id]

    if user.valid?
      user.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/list', params, user.errors
    end
  end

  post '/new_file_type', auth: :file_types_new do
    new_file_type = EmployeeFileType.new
    new_file_type[:type] = params[:type]

    if new_file_type.valid?
      new_file_type.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/list', params, new_file_type.errors
    end
  end

  post '/new_job_type', auth: :job_types_new do
    new_job_type = JobType.new
    new_job_type[:type] = params[:type]

    if new_job_type.valid?
      new_job_type.save
      redirect build_success_url '/control_panel/list', params[:redir]
    else
      redirect build_error_url '/control_panel/list', params, new_job_type.errors
    end
  end
end
