class ShiftBackupWorkHours < Sequel::Model
  plugin :validation_helpers
  def before_validation
    super
    self.hour_0 ||= 0.0
    self.hour_1 ||= 0.0
    self.hour_2 ||= 0.0
    self.hour_3 ||= 0.0
    self.hour_4 ||= 0.0
    self.hour_5 ||= 0.0
    self.hour_6 ||= 0.0
    self.hour_7 ||= 0.0
    self.hour_8 ||= 0.0
    self.hour_9 ||= 0.0
    self.hour_10 ||= 0.0
    self.hour_11 ||= 0.0
    self.hour_12 ||= 0.0
    self.hour_13 ||= 0.0
    self.hour_14 ||= 0.0
    self.hour_15 ||= 0.0
    self.hour_16 ||= 0.0
    self.hour_17 ||= 0.0
    self.hour_18 ||= 0.0
    self.hour_19 ||= 0.0
    self.hour_20 ||= 0.0
    self.hour_21 ||= 0.0
    self.hour_22 ||= 0.0
    self.hour_23 ||= 0.0
  end

  def validate
    super
    validates_presence %i[hour_0 hour_1 hour_2 hour_3 hour_4 hour_5 hour_6 hour_7 hour_8
                          hour_9 hour_10 hour_11 hour_12 hour_13 hour_14 hour_15 hour_16
                          hour_17 hour_18 hour_19 hour_20 hour_21 hour_22 hour_23
                          day_of_week], message: 'No puede estar vacío'
    validates_unique %i[shift_backup_id day_of_week], message: 'No puedes cargar dos work hours para el mismo día'
  end
end
