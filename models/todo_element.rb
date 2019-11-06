class TodoElement < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.response_message ||= ''
    self.response_score ||= 0
  end

  def validate
    super
    validates_presence %i[todo_list_id todo_short todo_detail], message: 'no puede estar vacío'
  end

  many_to_one :todo_list, key: :todo_list_id
end
