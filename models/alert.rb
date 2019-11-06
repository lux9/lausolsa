class Alert < Sequel::Model
  plugin :validation_helpers

  def before_save
    self.trigger_date = Date.today
  end

  def validate
    super
    validates_presence %i[alert_type message], message: 'no puede estar vacío'
    validates_unique %i[client_id alert_type], message: 'repite un trabajo ya cargado' unless client_id.nil?
    validates_unique %i[location_id alert_type], message: 'repite un trabajo ya cargado' unless location_id.nil?
    validates_unique %i[shift_id alert_type], message: 'repite un trabajo ya cargado' unless shift_id.nil?
    validates_unique %i[employee_id alert_type], message: 'repite un trabajo ya cargado' unless employee_id.nil?
  end

  many_to_one :client, key: :client_id
  many_to_one :location, key: :location_id
  many_to_one :shift, key: :shift_id
  many_to_one :employee, key: :employee_id
end