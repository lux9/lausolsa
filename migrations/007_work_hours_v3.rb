Sequel.migration do
  change do
    create_table(:shift_work_hours) do
      primary_key :id
      foreign_key :shift_id, :shifts, null: false, on_delete: :cascade
      String :day_of_week, default: 'monday', null: false
      Float :hour_0, null: false, default: 0.0
      Float :hour_1, null: false, default: 0.0
      Float :hour_2, null: false, default: 0.0
      Float :hour_3, null: false, default: 0.0
      Float :hour_4, null: false, default: 0.0
      Float :hour_5, null: false, default: 0.0
      Float :hour_6, null: false, default: 0.0
      Float :hour_7, null: false, default: 0.0
      Float :hour_8, null: false, default: 0.0
      Float :hour_9, null: false, default: 0.0
      Float :hour_10, null: false, default: 0.0
      Float :hour_11, null: false, default: 0.0
      Float :hour_12, null: false, default: 0.0
      Float :hour_13, null: false, default: 0.0
      Float :hour_14, null: false, default: 0.0
      Float :hour_15, null: false, default: 0.0
      Float :hour_16, null: false, default: 0.0
      Float :hour_17, null: false, default: 0.0
      Float :hour_18, null: false, default: 0.0
      Float :hour_19, null: false, default: 0.0
      Float :hour_20, null: false, default: 0.0
      Float :hour_21, null: false, default: 0.0
      Float :hour_22, null: false, default: 0.0
      Float :hour_23, null: false, default: 0.0
      unique %i[shift_id day_of_week]
    end
    create_table(:shift_backup_work_hours) do
      primary_key :id
      foreign_key :shift_backup_id, :shift_backups, null: false, on_delete: :cascade
      String :day_of_week, default: 'monday', null: false
      Float :hour_0, null: false, default: 0.0
      Float :hour_1, null: false, default: 0.0
      Float :hour_2, null: false, default: 0.0
      Float :hour_3, null: false, default: 0.0
      Float :hour_4, null: false, default: 0.0
      Float :hour_5, null: false, default: 0.0
      Float :hour_6, null: false, default: 0.0
      Float :hour_7, null: false, default: 0.0
      Float :hour_8, null: false, default: 0.0
      Float :hour_9, null: false, default: 0.0
      Float :hour_10, null: false, default: 0.0
      Float :hour_11, null: false, default: 0.0
      Float :hour_12, null: false, default: 0.0
      Float :hour_13, null: false, default: 0.0
      Float :hour_14, null: false, default: 0.0
      Float :hour_15, null: false, default: 0.0
      Float :hour_16, null: false, default: 0.0
      Float :hour_17, null: false, default: 0.0
      Float :hour_18, null: false, default: 0.0
      Float :hour_19, null: false, default: 0.0
      Float :hour_20, null: false, default: 0.0
      Float :hour_21, null: false, default: 0.0
      Float :hour_22, null: false, default: 0.0
      Float :hour_23, null: false, default: 0.0
      unique %i[shift_backup_id day_of_week]
    end
  end
end