class Client < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.archived ||= false
  end

  def validate
    super
    validates_presence %i[name cuit address_street address_number address_cp address_city
                          address_province address_country tax_condition], message: 'No puede estar vacío'
    validates_unique :name, message: 'Ya existe un cliente con este nombre'
    validates_unique :cuit, message: 'Ya existe un cliente con este CUIT'
    validates_schema_types %i[iva_perception iibb_perception], message: 'Valor inválido (Permitido: Sí / No)'
    validates_not_null %i[iva_perception iibb_perception], message: 'Valor inválido (Permitido: Sí / No)'

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

  one_to_many :locations
  one_to_many :shift_backups, key: :client_id
  one_to_many :shifts, key: :client_id
end
