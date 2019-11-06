Sequel.migration do
  change do
    create_table(:shift_backups) do
      primary_key :id
      foreign_key :employee_id, :employees, null: true
      foreign_key :client_id, :clients, null: false, on_delete: :cascade
      foreign_key :location_id, :locations, null: true, on_delete: :set_null
      foreign_key :type_id, :job_types, null: false
      Integer :request_id, null: false
      Date :date, null: false
      Time :start_time, only_time: true, null: false
      Time :end_time, only_time: true, null: false
      String :reason, text: true, null: false
      Float :hours, null: false
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
    end
    create_table(:shift_late_arrivals, ignore_index_errors: true) do
      primary_key :id
      foreign_key :client_id, :clients, null: true, on_delete: :set_null
      foreign_key :location_id, :locations, null: true, on_delete: :set_null
      foreign_key :employee_id, :employees, null: false, on_delete: :cascade
      foreign_key :shift_id, :shifts, null: true, on_delete: :set_null
      Date :date, null: false
      String :reason, text: true, null: true

      index %i[date employee_id shift_id], unique: true
      index [:date]
    end
  end
end
