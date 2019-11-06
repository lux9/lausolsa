Sequel.migration do
  change do
    alter_table(:shifts) do
      add_column :archived, TrueClass, default: false, null: false
    end
    alter_table(:locations) do
      add_column :archived, TrueClass, default: false, null: false
    end
    alter_table(:clients) do
      add_column :archived, TrueClass, default: false, null: false
    end
    alter_table(:employees) do
      add_column :archived, TrueClass, default: false, null: false
    end
  end
end