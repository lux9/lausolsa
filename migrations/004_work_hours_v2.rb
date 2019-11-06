Sequel.migration do
  change do
    create_table(:employee_available_hours) do
      primary_key :id
      foreign_key :employee_id, :employees, null: false
      String :day_of_week, default: 'monday', null: false
      Float :hour_0, null: false, default: 1.0
      Float :hour_1, null: false, default: 1.0
      Float :hour_2, null: false, default: 1.0
      Float :hour_3, null: false, default: 1.0
      Float :hour_4, null: false, default: 1.0
      Float :hour_5, null: false, default: 1.0
      Float :hour_6, null: false, default: 1.0
      Float :hour_7, null: false, default: 1.0
      Float :hour_8, null: false, default: 1.0
      Float :hour_9, null: false, default: 1.0
      Float :hour_10, null: false, default: 1.0
      Float :hour_11, null: false, default: 1.0
      Float :hour_12, null: false, default: 1.0
      Float :hour_13, null: false, default: 1.0
      Float :hour_14, null: false, default: 1.0
      Float :hour_15, null: false, default: 1.0
      Float :hour_16, null: false, default: 1.0
      Float :hour_17, null: false, default: 1.0
      Float :hour_18, null: false, default: 1.0
      Float :hour_19, null: false, default: 1.0
      Float :hour_20, null: false, default: 1.0
      Float :hour_21, null: false, default: 1.0
      Float :hour_22, null: false, default: 1.0
      Float :hour_23, null: false, default: 1.0
      unique %i[employee_id day_of_week]
    end
    alter_table(:shifts) do
      add_column :hour_0, Float, null: false, default: 0.0
      add_column :hour_1, Float, null: false, default: 0.0
      add_column :hour_2, Float, null: false, default: 0.0
      add_column :hour_3, Float, null: false, default: 0.0
      add_column :hour_4, Float, null: false, default: 0.0
      add_column :hour_5, Float, null: false, default: 0.0
      add_column :hour_6, Float, null: false, default: 0.0
      add_column :hour_7, Float, null: false, default: 0.0
      add_column :hour_8, Float, null: false, default: 0.0
      add_column :hour_9, Float, null: false, default: 0.0
      add_column :hour_10, Float, null: false, default: 0.0
      add_column :hour_11, Float, null: false, default: 0.0
      add_column :hour_12, Float, null: false, default: 0.0
      add_column :hour_13, Float, null: false, default: 0.0
      add_column :hour_14, Float, null: false, default: 0.0
      add_column :hour_15, Float, null: false, default: 0.0
      add_column :hour_16, Float, null: false, default: 0.0
      add_column :hour_17, Float, null: false, default: 0.0
      add_column :hour_18, Float, null: false, default: 0.0
      add_column :hour_19, Float, null: false, default: 0.0
      add_column :hour_20, Float, null: false, default: 0.0
      add_column :hour_21, Float, null: false, default: 0.0
      add_column :hour_22, Float, null: false, default: 0.0
      add_column :hour_23, Float, null: false, default: 0.0
      add_column :weekly_hours, Float, null: false, default: 0.0
    end
    alter_table(:employees) do
      add_column :max_weekly_hours, Float, null: false, default: 0.0
    end
  end
end
