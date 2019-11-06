class EmployeeOvertime < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[date hours start_time end_time reason], message: 'No puede estar vacío'
    validates_schema_types %i[date], message: 'No es válido (AAAA-MM-DD)'
    validates_schema_types %i[start_time end_time], message: 'No es válido (23:00)'
    errors.add(:end_time, 'Debe ser diferente a la hora de inicio') if end_time && start_time && end_time == start_time
    errors.add(:end_time, 'No puede ser anterior a la fecha de inicio') if end_time && start_time && end_time < start_time && end_time != Sequel::SQLTime.create(0,0,0)
    errors.add(:date, 'Colisiona con un turno, ausencia o suplencia existente') if date == Date.new(2001,01,01)
  end

  def before_save
    self.double_pay ||= false
    self.night_time ||= false
    super
  end

  many_to_one :employee, key: :employee_id
  many_to_one :client, key: :client_id
  many_to_one :location, key: :location_id
end
