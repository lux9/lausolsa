class ActionLog < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence %i[message details admin_id date_time], message: 'no puede estar vacío'
  end

  many_to_one :user, key: :admin_id
end
