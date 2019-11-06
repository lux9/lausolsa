class Shift < Sequel::Model
  plugin :validation_helpers

  def before_validation
    super
    self.archived ||= false
    self.end_date ||= Date.new(2099, 1, 1)
  end

  def validate
    super
    if [monday, tuesday, wednesday, thursday, friday, saturday, sunday].all? { |day| day.nil? }
      errors.add(:monday, 'debes elegir al menos un día')
      errors.add(:tuesday, 'debes elegir al menos un día')
      errors.add(:wednesday, 'debes elegir al menos un día')
      errors.add(:thursday, 'debes elegir al menos un día')
      errors.add(:friday, 'debes elegir al menos un día')
      errors.add(:saturday, 'debes elegir al menos un día')
      errors.add(:sunday, 'debes elegir al menos un día')
    end
    validates_presence %i[location_id type_id start_date end_date start_time end_time], message: 'no puede estar vacío'
    validates_integer [:location_id], message: 'no es un valor esperado'
    validates_schema_types %i[start_date end_date start_time end_time 
                              includes_holidays all_holidays], message: 'no es un valor esperado (tipo fecha)'
    errors.add(:end_time, 'no puede ser igual a la hora de inicio') if end_time && start_time && end_time == start_time
    # this allows shifts staring on a day and ending on the next
    # errors.add(:end_time, 'No puede ser anterior a la fecha de inicio') if end_time && start_time && end_time < start_time && end_time != Sequel::SQLTime.create(0,0,0)
  end

  def days
    shift_days = []
    shift_days << :monday if self.monday
    shift_days << :tuesday if self.tuesday
    shift_days << :wednesday if self.wednesday
    shift_days << :thursday if self.thursday
    shift_days << :friday if self.friday
    shift_days << :saturday if self.saturday
    shift_days << :sunday if self.sunday
    shift_days
  end

  many_to_one :location, key: :location_id
  many_to_one :employee, key: :employee_id
  many_to_one :client, key: :client_id
  many_to_one :type, key: :type_id, class: "JobType"
  one_to_many :absences, key: :shift_id, class: "ShiftAbsence"
  one_to_many :work_hours, key: :shift_id, class: "ShiftWorkHours"
end
