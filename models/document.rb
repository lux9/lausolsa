class Document < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[name content type], message: 'No puede estar vacío'

    allowed_type = %w(employee client general)
    errors.add(:type, "Valor inválido (Permitido: #{allowed_type.join(', ')})") unless allowed_type.include?(type)
  end
end
