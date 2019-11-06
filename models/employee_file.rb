class EmployeeFile < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[date_time employee_id description path], message: 'no puede estar vacío'
  end

  many_to_one :user, key: :uploader_id
  many_to_one :employee, key: :employee_id
  many_to_one :type, key: :file_type_id, class: "EmployeeFileType"
end
