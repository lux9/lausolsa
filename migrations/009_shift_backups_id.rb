Sequel.migration do
  up do
    alter_table(:shift_backups) do
      set_column_type :request_id, String
    end
  end
  down do
    alter_table(:shift_backups) do
      set_column_type :request_id, Integer
    end
  end
end
