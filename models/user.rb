class User < Sequel::Model
  plugin :secure_password
  plugin :validation_helpers

  def before_validate
    super
    self.archived ||= false
    self.role_id ||= 0
  end

  def validate
    super
    validates_presence %i[email first_name last_name], message: 'no puede estar vacío'
    validates_unique :email, message: 'ya existe un usuario con este correo'
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def name
    full_name
  end

  many_to_one :role, key: :role_id, class: 'UserRole'
end
