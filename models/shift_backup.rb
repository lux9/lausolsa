class ShiftBackup < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[client_id location_id type_id request_id date start_time end_time], message: 'no puede estar vacío'
    validates_integer %i[client_id location_id], message: 'no es un valor esperado'
    validates_schema_types %i[date], message: 'no es un valor esperado (tipo fecha)'
    errors.add(:end_time, 'no puede ser igual a la hora de inicio') if end_time && end_time == start_time
    # esto permite horarios de 23 a 02 hs
    # errors.add(:end_time, 'No puede ser anterior a la hora de inicio') if end_time && start_time && end_time < start_time && end_time != Sequel::SQLTime.create(0,0,0)
  end

  many_to_one :location, key: :location_id
  many_to_one :employee, key: :employee_id
  many_to_one :client, key: :client_id
  many_to_one :type, key: :type_id, class: "JobType"
  one_to_many :work_hours, key: :shift_backup_id, class: "ShiftBackupWorkHours"
end