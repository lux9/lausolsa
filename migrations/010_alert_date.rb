Sequel.migration do
  change do
    alter_table(:alerts) do
      add_column :trigger_date, DateTime, default: DateTime.new(2019, 1, 1, 0, 0, 0), null: false
    end
  end
end