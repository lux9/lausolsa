Sequel.migration do
  up do
    create_table(:user_roles) do
      primary_key :id
      String :name, :text=>true, :null=>false
      String :privileges, :text=>true, :default=> '{}', :null=>false
      index [:name], :unique=>true
    end
    self[:user_roles].insert(0, 'Usuario', '{}')
    self[:user_roles].insert(1, 'Administrador', '{"absence_new":true,"absence_license_new":true,"absence_assign":true,"absence_unassign":true,"absence_cancel":true,"client_new":true,"client_logo":true,"client_archive":true,"client_unarchive":true,"location_new":true,"location_contract_edit":true,"location_archive":true,"location_unarchive":true,"shift_new":true,"shift_assign":true,"shift_unassign":true,"shift_delete":true,"shift_backup_new":true,"shift_backup_assign":true,"shift_backup_unassign":true,"shift_backup_delete":true,"employee_new":true,"employee_avatar":true,"employee_availability":true,"employee_archive":true,"employee_unarchive":true,"late_arrival_new":true,"late_arrival_delete":true,"overtime_new":true,"overtime_delete":true,"employee_file_new":true,"employee_file_delete":true,"holiday_new":true,"holiday_delete":true,"document_new":true,"document_delete":true,"document_employee":true,"job_types_new":true,"job_types_delete":true,"file_types_new":true,"file_types_delete":true,"users_new":true,"users_password":true,"users_role":true,"users_delete":true,"roles_new":true,"roles_delete":true}')
    alter_table(:users) do
      add_foreign_key :role_id, :user_roles, :default=> 0, :null=>false, :key=>[:id]
    end
  end

  down do
    alter_table(:users) do
      drop_foreign_key :role_id
    end
    drop_table(:user_roles)
  end
end