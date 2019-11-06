class JobType < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:type], message: 'no puede estar vacío'
    validates_unique :type, message: 'repite un tipo ya cargado'
  end
end
