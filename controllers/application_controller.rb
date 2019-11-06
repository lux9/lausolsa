class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, AuthHelper, ActionLogHelper, AlertHelper,
          AbsenceHelper, ClientHelper, DocumentHelper, LocationHelper, EmployeeHelper,
          ShiftHelper, ShiftBackupHelper, ViewHelper, ExportHelper, ControlPanelHelper

  # set folder for templates to ../views, but make the path absolute
  set :views, (proc { File.join(root, '../views') })
  set :public_folder, (proc { File.join(root, '../public') })

  # don't enable logging when running tests
  configure :production, :development do
    enable :logging
  end

  configure :local, :development do
    set :show_exceptions, true
  end

  register do
    def auth(type)
      condition do
        redirect "/auth/login?redir=#{request.fullpath}" if @user.nil?
        redirect '/403' unless user_matches_type(type)
      end
    end
  end

  def json_to_params
    JSON.parse request.body.read, symbolize_names: true
  rescue JSON::ParserError
    {}
  end

  before do
    @user = session[:user] || session_data_from_token(request.env['HTTP_X_USER_TOKEN'])
    json_to_params.each { |p| params[p[0]] = p[1] }
  end

  module GetOrPost
    def get_or_post(path, options = {}, &block)
      get(path, options, &block)
      post(path, options, &block)
    end
  end
  register GetOrPost

  get '/' do
    redirect "/auth/login?redir=#{request.fullpath}" if @user.nil?

    absence_count = ShiftAbsence.where(replacement_id: nil)
                                .where { absence_date >= Date.today }
                                .count

    erb :home, locals: { menu: [:home],
                         breadcrumb: [{ url: '/', name: 'Inicio' }],
                         clients_count: Client.count,
                         employees_count: Employee.count,
                         shifts_count: Shift.where(employee_id: nil).count,
                         alerts_count: Alert.count,
                         absences_count: absence_count }
  end

  get '/initialize' do
    [
      # email, password, name, surname
      %w[kuteninja@gmail.com adbs2004 Emiliano Perez],
      %w[frano.criscuolo@gmail.com prueba Francisco Criscuolo],
      %w[o.blanco@fibertel.com.ar 4321 Osvaldo Blanco],
      %w[hernan.t@lausolsa.com.ar 1234 Hernán Tyntenfisz],
      %w[damian.laurenzi@gmail.com dl-1234 Damián Laurenzi],
      %w[claulima1758@gmail.com 4321 Claudia Lima],
      %w[vlesmes@lausolsa.com.ar 4321 Viviana Lesmes],
      %w[test@test.com 4321 test test]
    ].each do |user_data|
      user = User.new
      user.email = user_data[0]
      user.password = user_data[1]
      user.password_confirmation = user_data[1]
      user.first_name = user_data[2]
      user.last_name = user_data[3]
      user.role_id = 1
      user.save if user.valid?
    end

    %w[Maestranza Supervisor Director Administrativo Coordinador Oficial].each do |t|
      job_type = JobType.new
      job_type.type = t
      job_type.save if job_type.valid?
    end

    ['Parte Médico', 'Documento de identidad', 'Capacitación', 'Título o diploma', 'Documento legal', 'Otros'].each do |ft|
      employee_file_type = EmployeeFileType.new
      employee_file_type.type = ft
      employee_file_type.save if employee_file_type.valid?
    end

    'ok'
  end

  get_or_post '/test-image' do
    halt 200, 'No image' if params[:image].nil?

    begin
      # image = GD2::Image.load(params[:image])
      FileUtils.rm './public/upload/testing.png', force: true
      # image.export('./public/upload/testing.jpg', quality: 95)
      File.binwrite './public/upload/testing.png', params[:image].pack('C*')
      'OK'
    rescue StandardError => e
      "Pasaron cosas: #{e}"
    end
  end

  get '/403' do
    status 403
    '403 - No autorizado'
  end

  get '/404' do
    status 404
    '404 - No se encuentra'
  end

  get '/*' do
    redirect '/404'
  end
end
