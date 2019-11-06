class EmployeeAbsence < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.notice_date ||= Date.today
    self.justified ||= false
  end

  def validate
    super
    validates_presence %i[absence_start_date absence_end_date notice_date reason], message: 'no puede estar vacío'
    validates_schema_types %i[absence_start_date absence_end_date], message: 'no es un valor esperado (tipo fecha)'
  end

  many_to_one :employee, key: :employee_id
  one_to_many :shift_absences, key: :employee_absence_id
  one_to_many :employee_absence_files, key: :employee_absence_id
end
