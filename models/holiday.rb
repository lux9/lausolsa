class Holiday < Sequel::Model
  plugin :validation_helpers
  def validate
    super
    validates_presence %i[holiday_date comment], message: 'no puede estar vacío'
    validates_unique :holiday_date, message: 'ya está cargada esta fecha'
  end
end
