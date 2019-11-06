class EmployeeAbsenceFile < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[employee_id employee_absence_id employee_file_id doctor_license
                          doctor_name message license_start_date license_end_date], message: 'no puede estar vacío'
    validates_schema_types %i[license_start_date license_end_date], message: 'no es un valor esperado (tipo fecha)'
  end

  many_to_one :employee, key: :employee_id
  many_to_one :employee_absence, key: :employee_absence_id
  many_to_one :employee_file, key: :employee_file_id
end
