Sequel.migration do
  change do
    extension :pg_json
    alter_table(:employees) do
      add_column :work_hours, :jsonb, null: false
      add_index :work_hours, type: :gin
    end
  end
end
