Sequel.migration do
  change do
    alter_table(:employee_overtimes) do
      add_column :double_pay, TrueClass, default: false, null: false
      add_column :night_time, TrueClass, default: false, null: false
    end
    alter_table(:employee_absences) do
      add_column :justified, TrueClass, default: false, null: false
      add_column :notice_date, Date, default: Date.new(2019, 5, 1), null: false
    end
  end
end
