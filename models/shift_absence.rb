class ShiftAbsence < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[location_id absence_id shift_id absence_date reason], message: 'no puede estar vacío'
    validates_schema_types %i[absence_date], message: 'no es un valor esperado (tipo fecha)'
    validates_unique %i[absence_date absence_id shift_id], message: 'repite una ausencia ya cargada'
  end

  many_to_one :client, key: :client_id
  many_to_one :location, key: :location_id
  many_to_one :absent_employee, key: :absence_id, class: 'Employee'
  many_to_one :replacement_employee, key: :replacement_id, class: 'Employee'
  many_to_one :shift, key: :shift_id
  many_to_one :employee_absence, key: :employee_absence_id, class: 'EmployeeAbsence'
end
