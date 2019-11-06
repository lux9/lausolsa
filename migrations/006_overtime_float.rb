Sequel.migration do
  up do
    alter_table(:employee_overtimes) do
      set_column_type :hours, Float
    end
  end
  down do
    alter_table(:employee_overtimes) do
      set_column_type :hours, Integer
    end
  end
end