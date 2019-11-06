Sequel.migration do
  change do
    create_table(:todo_lists) do
      primary_key :id

      foreign_key :client_id, :clients, null: false
      foreign_key :location_id, :locations, null: false
      foreign_key :employee_id, :employees, null: true

      Date :creation_date, null: false
      Date :expiration_date, null: true
      Date :completion_date, null: true

      Float :total_score, null: true
    end

    create_table(:todo_elements) do
      primary_key :id

      foreign_key :todo_list_id, :todo_lists, null: false

      String :todo_short, null: false
      String :todo_detail, null: false

      String :response_message, null: false
      Integer :response_score, null: true
    end

    create_table(:todo_element_photos) do
      primary_key :id

      foreign_key :todo_element_id, :todo_lists, null: false

      String :path, null: false
    end
  end
end
