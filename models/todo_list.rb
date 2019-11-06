class TodoList < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.creation_date ||= Date.today
  end

  def validate
    super
    validates_presence %i[client_id location_id creation_date], message: 'no puede estar vacío'
  end

  many_to_one :client, key: :client_id
  many_to_one :location, key: :location_id
  many_to_one :employee, key: :employee_id
  one_to_many :elements, key: :todo_list_id, class: 'TodoElement'
end
