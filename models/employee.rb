class Employee < Sequel::Model
  plugin :validation_helpers
  def before_validation
    super
    self.archived ||= false
    self.marital_status = self.marital_status
                              .gsub(/Soltero$|Soltera$/i, 'Soltero/a')
                              .gsub(/Casado$|Casada$/i, 'Casado/a')
                              .gsub(/Separado$|Separada$/i, 'Separado/a')
                              .gsub(/Divorciado$|Divorciada$/i, 'Divorciado/a')
                              .gsub(/Viudo$|Viuda$/i, 'Viudo/a')
  end

  def validate
    super
    validates_presence %i[first_name last_name cuit gender address_street
                          address_city address_province address_country
                          type_id], message: 'No puede estar vacío'
    validates_integer %i[address_number address_cp], message: 'Debe ser un número'
    validates_integer %i[type_id], message: 'No es un tipo válido'
    validates_unique :cuit, message: 'Ya existe un empleado con este CUIT'
    validates_schema_types %i[worker_union works_holidays], message: 'Valor inválido (Permitido: Sí / No)'
    validates_not_null %i[worker_union works_holidays], message: 'Valor inválido (Permitido: Sí / No)'

    allowed_marital_status = %w[Soltero/a Casado/a Separado/a Divorciado/a Viudo/a Otro]
    unless allowed_marital_status.include?(marital_status)
      errors.add(:marital_status, "Valor inválido (Permitido: #{allowed_marital_status.join(', ')})")
    end

    allowed_province = ['Ciudad Autónoma de Buenos Aires', 'Buenos Aires',
                        'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes',
                        'Entre Ríos', 'Formosa', 'Jujuy', 'La Pampa', 'La Rioja',
                        'Mendoza', 'Misiones', 'Neuquén', 'Río Negro', 'Salta',
                        'San Juan', 'Santa Cruz', 'Santa Fe', 'Santiago del Estero',
                        'Tierra del Fuego', 'Tucumán']
    unless allowed_province.include?(address_province)
      errors.add(:address_province, "Valor inválido (Permitido: #{allowed_province.join(', ')})")
    end

    allowed_country = ['Argentina']
    unless allowed_country.include?(address_country)
      errors.add(:address_country, "Valor inválido (Permitido: #{allowed_country.join(', ')})")
    end

    errors.add(:cuit, "Valor inválido") if cuit == 'invalid'
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def sortable_name
    "#{last_name}, #{first_name}"
  end

  def name
    full_name
  end

  one_to_many :shifts, key: :employee_id
  many_to_one :type, key: :type_id, class: "JobType"
  one_to_many :employee_absences, key: :employee_id, class: "EmployeeAbsence"
  one_to_many :shift_absences, key: :absence_id, class: "ShiftAbsence"
  one_to_many :shift_replacements, key: :replacement_id, class: "ShiftAbsence"
  one_to_many :files, key: :employee_id, class: "EmployeeFile"
  one_to_many :overtime, key: :employee_id, class: "EmployeeOvertime"
  one_to_many :available_hours, key: :employee_id, class: "EmployeeAvailableHours"
  one_to_many :late_arrivals, key: :employee_id, class: "ShiftLateArrival"
  one_to_many :shift_backups, key: :employee_id, class: "ShiftBackup"
end
