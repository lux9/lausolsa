Sequel.migration do
  change do
    create_table(:clients, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true, :null=>false
      String :cuit, :text=>true, :null=>false
      String :address_street, :text=>true, :null=>false
      String :address_street_between, :text=>true
      String :address_number, :text=>true, :null=>false
      String :address_extra, :text=>true
      String :address_cp, :text=>true, :null=>false
      String :address_city, :text=>true, :null=>false
      String :address_province, :text=>true, :null=>false
      String :address_country, :text=>true, :null=>false
      String :tax_condition, :text=>true, :null=>false
      String :iibb, :text=>true
      TrueClass :iva_perception, :null=>false
      TrueClass :iibb_perception, :null=>false
      
      index [:cuit], :name=>:clients_cuit_key, :unique=>true
      index [:name], :name=>:clients_name_key, :unique=>true
    end
    
    create_table(:documents, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true, :null=>false
      String :content, :text=>true, :null=>false
      String :type, :text=>true, :null=>false
      
      index [:name], :name=>:documents_name_key, :unique=>true
    end
    
    create_table(:employee_file_types, :ignore_index_errors=>true) do
      primary_key :id
      String :type, :text=>true, :null=>false
      
      index [:type], :name=>:employee_file_types_type_key, :unique=>true
    end
    
    create_table(:holidays, :ignore_index_errors=>true) do
      primary_key :id
      Date :holiday_date, :null=>false
      String :comment, :text=>true, :null=>false
      
      index [:holiday_date], :name=>:holidays_holiday_date_key, :unique=>true
    end
    
    create_table(:job_types, :ignore_index_errors=>true) do
      primary_key :id
      String :type, :text=>true, :null=>false
      
      index [:type], :name=>:job_types_type_key, :unique=>true
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :email, :text=>true, :null=>false
      String :password_digest, :text=>true
      String :first_name, :text=>true, :null=>false
      String :last_name, :text=>true, :null=>false
      
      index [:email], :name=>:users_email_key, :unique=>true
    end
    
    create_table(:employees, :ignore_index_errors=>true) do
      primary_key :id
      String :first_name, :text=>true, :null=>false
      String :last_name, :text=>true, :null=>false
      String :cuit, :text=>true, :null=>false
      String :file_number, :text=>true
      String :gender, :text=>true, :null=>false
      String :phone_mobile, :text=>true
      String :phone_home, :text=>true
      Date :birthday, :null=>false
      String :marital_status, :text=>true, :null=>false
      Date :join_date, :null=>false
      Date :leave_date
      String :leave_reason, :text=>true
      String :address_street, :text=>true, :null=>false
      String :address_street_between, :text=>true
      String :address_number, :text=>true, :null=>false
      String :address_extra, :text=>true
      String :address_cp, :text=>true, :null=>false
      String :address_city, :text=>true, :null=>false
      String :address_province, :text=>true, :null=>false
      String :address_country, :text=>true, :null=>false
      foreign_key :type_id, :job_types, :null=>false, :key=>[:id]
      String :cbu, :text=>true
      TrueClass :worker_union, :null=>false
      TrueClass :works_holidays, :null=>false
      String :comment, :text=>true
      
      index [:cuit], :name=>:employees_cuit_key, :unique=>true
      index [:first_name, :last_name], :name=>:employees_first_name_last_name_key, :unique=>true
    end
    
    create_table(:locations, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :client_id, :clients, :null=>false, :key=>[:id], :on_delete=>:cascade
      String :name, :text=>true, :null=>false
      String :address_street, :text=>true, :null=>false
      String :address_street_between, :text=>true
      String :address_number, :text=>true, :null=>false
      String :address_extra, :text=>true
      String :address_cp, :text=>true, :null=>false
      String :address_city, :text=>true, :null=>false
      String :address_province, :text=>true, :null=>false
      String :address_country, :text=>true, :null=>false
      Integer :parent_id
      Integer :min_employees, :default=>0, :null=>false
      TrueClass :supervisor_needed, :default=>false, :null=>false
      Date :end_date, :default=>Date.new(2099, 1, 1), :null=>false
      
      index [:name, :client_id], :name=>:locations_name_client_id_key, :unique=>true
      index [:name, :parent_id, :client_id], :name=>:locations_name_parent_id_client_id_key, :unique=>true
    end
    
    create_table(:action_logs) do
      primary_key :id
      DateTime :date_time, :null=>false
      foreign_key :admin_id, :users, :key=>[:id], :on_delete=>:set_null
      foreign_key :client_id, :clients, :key=>[:id], :on_delete=>:set_null
      foreign_key :location_id, :locations, :key=>[:id], :on_delete=>:set_null
      foreign_key :employee_id, :employees, :key=>[:id], :on_delete=>:set_null
      String :message, :text=>true, :null=>false
      String :details, :text=>true, :null=>false
    end
    
    create_table(:employee_absences) do
      primary_key :id
      foreign_key :employee_id, :employees, :null=>false, :key=>[:id], :on_delete=>:cascade
      Date :absence_start_date, :null=>false
      Date :absence_end_date, :null=>false
      String :reason, :text=>true, :null=>false
    end
    
    create_table(:employee_files) do
      primary_key :id
      DateTime :date_time, :null=>false
      foreign_key :uploader_id, :users, :null=>false, :key=>[:id], :on_delete=>:set_null
      foreign_key :employee_id, :employees, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :file_type_id, :employee_file_types, :null=>false, :key=>[:id]
      String :description, :text=>true, :null=>false
      String :path, :text=>true, :null=>false
    end
    
    create_table(:employee_overtimes, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :employee_id, :employees, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :client_id, :clients, :null=>false, :key=>[:id], :on_delete=>:set_null
      foreign_key :location_id, :locations, :null=>false, :key=>[:id], :on_delete=>:set_null
      Date :date, :null=>false
      Time :start_time, :only_time=>true, :null=>false
      Time :end_time, :only_time=>true, :null=>false
      String :reason, :text=>true, :null=>false
      Integer :hours, :null=>false
      
      index [:employee_id, :date, :start_time, :end_time], :name=>:employee_overtimes_employee_id_date_start_time_end_time_key, :unique=>true
    end
    
    create_table(:shifts) do
      primary_key :id
      foreign_key :client_id, :clients, :null=>false, :key=>[:id]
      foreign_key :location_id, :locations, :null=>false, :key=>[:id]
      foreign_key :employee_id, :employees, :key=>[:id]
      TrueClass :monday, :default=>false
      TrueClass :tuesday, :default=>false
      TrueClass :wednesday, :default=>false
      TrueClass :thursday, :default=>false
      TrueClass :friday, :default=>false
      TrueClass :saturday, :default=>false
      TrueClass :sunday, :default=>false
      Date :start_date, :null=>false
      Date :end_date, :default=>Date.new(2099, 1, 1), :null=>false
      foreign_key :type_id, :job_types, :null=>false, :key=>[:id]
      Time :start_time, :only_time=>true
      Time :end_time, :only_time=>true
      TrueClass :includes_holidays, :null=>false
      TrueClass :all_holidays, :null=>false
    end
    
    create_table(:alerts) do
      primary_key :id
      foreign_key :client_id, :clients, :key=>[:id], :on_delete=>:cascade
      foreign_key :location_id, :locations, :key=>[:id], :on_delete=>:cascade
      foreign_key :shift_id, :shifts, :key=>[:id], :on_delete=>:cascade
      foreign_key :employee_id, :employees, :key=>[:id], :on_delete=>:cascade
      String :alert_type, :text=>true, :null=>false
      String :message, :text=>true, :null=>false
    end
    
    create_table(:employee_absence_files) do
      primary_key :id
      foreign_key :employee_id, :employees, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :employee_absence_id, :employee_absences, :key=>[:id], :on_delete=>:set_null
      foreign_key :employee_file_id, :employee_files, :key=>[:id], :on_delete=>:cascade
      String :doctor_license, :text=>true, :null=>false
      String :doctor_name, :text=>true, :null=>false
      String :message, :text=>true, :null=>false
      Date :license_start_date, :null=>false
      Date :license_end_date, :null=>false
    end
    
    create_table(:shift_absences, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :client_id, :clients, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :location_id, :locations, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :absence_id, :employees, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :replacement_id, :employees, :key=>[:id], :on_delete=>:set_null
      foreign_key :shift_id, :shifts, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :employee_absence_id, :employee_absences, :key=>[:id], :on_delete=>:set_null
      Date :absence_date, :null=>false
      String :reason, :text=>true, :null=>false
      
      index [:absence_date, :absence_id, :shift_id], :name=>:shift_absences_absence_date_absence_id_shift_id_key, :unique=>true
      index [:absence_date]
      index [:replacement_id]
    end
  end
end
