Encoding.default_external = Encoding::UTF_8

# Dependencies
require 'rubygems'
require 'sinatra/base'
require 'redis-store'
require 'redis-rack'
require 'sequel'
require 'bcrypt'
require 'json'
require 'jwt'
require 'markdown'
require 'sequel_secure_password'
require 'gd2-ffij'
require 'csv'
require 'roo'
require 'yaml'

# Environment Setup
environment = ENV['RACK_ENV'] || 'local'
config_file = File.expand_path("./config/#{environment}.yml")
unless File.exist?(config_file)
  raise StandardError, "No config file was found at #{config_file}"
end
config = YAML.safe_load(File.open(config_file), [Symbol])

# Redis Sessions
use Rack::Session::Redis, config[:session]

# Postgres
DB = Sequel.connect(config[:database])
Sequel.extension :core_extensions, :inflector
DB.extension :pg_json
DB.extension :pagination
Sequel.extension :pg_array_ops
Sequel.extension :pg_json_ops

# Migrate, except when testing
if environment != 'local'
  Sequel.extension :migration
  Sequel::Migrator.run(DB, './migrations')
end

# Models
require_relative 'models/user'
require_relative 'models/user_roles'
require_relative 'models/job_types'
require_relative 'models/client'
require_relative 'models/employee'
require_relative 'models/employee_absence'
require_relative 'models/employee_file_types'
require_relative 'models/employee_file'
require_relative 'models/employee_absence_file'
require_relative 'models/employee_available_hours'
require_relative 'models/holiday'
require_relative 'models/location'
require_relative 'models/shift'
require_relative 'models/shift_absence'
require_relative 'models/shift_backup'
require_relative 'models/shift_backup_work_hours'
require_relative 'models/shift_late_arrival'
require_relative 'models/shift_work_hours'
require_relative 'models/action_log'
require_relative 'models/alert'
require_relative 'models/employee_overtime'
require_relative 'models/document'
require_relative 'models/todo_list'
require_relative 'models/todo_element'

# Helpers
require_relative 'helpers/application_helper'
require_relative 'helpers/auth_helper'
require_relative 'helpers/absence_helper'
require_relative 'helpers/document_helper'
require_relative 'helpers/shift_helper'
require_relative 'helpers/shift_backup_helper'
require_relative 'helpers/employee_helper'
require_relative 'helpers/client_helper'
require_relative 'helpers/location_helper'
require_relative 'helpers/view_helper'
require_relative 'helpers/action_log_helper'
require_relative 'helpers/alert_helper'
require_relative 'helpers/export_helper'
require_relative 'helpers/control_panel_helper'

# Controllers
require_relative 'controllers/application_controller'
require_relative 'controllers/action_log_controller'
require_relative 'controllers/alert_controller'
require_relative 'controllers/client_controller'
require_relative 'controllers/auth_controller'
require_relative 'controllers/absence_controller'
require_relative 'controllers/employee_controller'
require_relative 'controllers/location_controller'
require_relative 'controllers/shift_controller'
require_relative 'controllers/shift_backup_controller'
require_relative 'controllers/holiday_controller'
require_relative 'controllers/import_controller'
require_relative 'controllers/export_controller'
require_relative 'controllers/document_controller'
require_relative 'controllers/control_panel_controller'
require_relative 'controllers/todo_controller'

# Routes
map('/absence') { run AbsenceController }
map('/action_log') { run ActionLogController }
map('/alert') { run AlertController }
map('/auth') { run AuthController }
map('/client') { run ClientController }
map('/employee') { run EmployeeController }
map('/location') { run LocationController }
map('/shift_backup') { run ShiftBackupController }
map('/shift') { run ShiftController }
map('/holiday') { run HolidayController }
map('/import') { run ImportController }
map('/export') { run ExportController }
map('/document') { run DocumentController }
map('/control_panel') { run ControlPanelController }
map('/todo') { run TodoController }
map('/') { run ApplicationController }

# Go go power rangers!
run Sinatra::Application
