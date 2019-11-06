class UserRole < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[name privileges], message: 'no puede estar vacío'
    validates_unique :name, message: 'ya existe un role con este nombre'
  end

  one_to_many :users, key: :role_id
end
