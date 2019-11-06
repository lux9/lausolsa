class ShiftLateArrival < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.date ||= Date.today
  end

  def validate
    super
    validates_presence %i[client_id location_id shift_id employee_id date], message: 'no puede estar vacío'
    validates_integer %i[client_id location_id shift_id employee_id], message: 'no es un valor esperado'
    validates_schema_types %i[date], message: 'no es un valor esperado (tipo fecha)'
    validates_unique %i[date employee_id shift_id], message: 'ya está cargada esta llegada tarde'
  end

  many_to_one :employee, key: :employee_id
  many_to_one :shift, key: :shift_id
  many_to_one :location, key: :location_id
  many_to_one :client, key: :client_id
end
