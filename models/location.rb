class Location < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.archived ||= false
    self.supervisor_needed ||= false
    self.min_employees ||= 0
    self.end_date ||= Date.new(2099, 1, 1)
  end

  def validate
    super
    validates_presence %i[client_id name address_street address_city address_cp
                          address_province address_country], message: 'No puede estar vacío'
    validates_integer %i[address_number address_cp], message: 'Debe ser un número'
    validates_schema_types [:end_date], message: 'Debe ser una fecha válida'
    validates_schema_types %i[supervisor_needed], message: 'Valor inválido (Permitido: Sí / No)'
    validates_not_null %i[supervisor_needed], message: 'Valor inválido (Permitido: Sí / No)'
    validates_unique %i[name client_id], message: 'Ya existe una estación con ese nombre en este cliente'
    validates_unique %i[name parent_id client_id], message: 'Ya existe una estación con ese nombre en este cliente'
  end

  def full_name
    parent.nil? ? name : parent.full_name + ' -> ' + name
  end

  def short_address
    address = "#{address_street} #{address_number}"
    address += "\n#{address_extra}" unless address_extra.nil? || address_extra.empty?
    address += "\n#{address_street_between}" unless address_street_between.nil? || address_street_between.empty?
    address += "\n#{address_city}, #{address_province}"
    address
  end

  many_to_one :client, key: :client_id
  many_to_one :parent, class: self
  one_to_many :children, key: :parent_id, class: self
  one_to_many :shifts, key: :location_id
  one_to_many :shift_backups, key: :location_id
  one_to_many :overtime, key: :location_id, class: "EmployeeOvertime"
end
