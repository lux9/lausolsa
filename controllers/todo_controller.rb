class TodoController < ApplicationController
  get '/', provides: %i[html json], auth: :user do
    if request.accept.any? { |a| a.to_s =~ /json/ }
      {
        form_list: TodoList.where { :completion_date <= Date.today }.map do |todo_list|
          {
            id: todo_list[:id],

            client_id: todo_list[:client_id],
            client_name: todo_list.client[:name],

            location_id: todo_list.location[:id],
            location_name: todo_list.location.full_name,
            location_address: todo_list.location.short_address,

            creation_date: todo_list[:creation_date].to_s,
            expiration_date: todo_list[:expiration_date].to_s,
            completion_date: todo_list[:completion_date].to_s,

            total_score: todo_list[:total_score].to_f,

            activities: todo_list.elements.map do |element|
              {
                id: element[:id],
                title: element[:todo_short],
                detail: element[:todo_detail],
                response_message: element[:response_message].to_s,
                response_score: element[:response_score].to_i,
                images: []
              }
            end
          }
        end
      }.to_json
    else
      # TODO: THIS
      todo = TodoList[2]
      to_print = TodoList.columns.each_with_object({}) { |key, result| result[key] = todo[key] }
      to_print[:activities] = todo.elements.map { TodoElement.columns.each_with_object({}) { |key, result| result[key] = todo[key] } }
      to_print.to_json
    end
  end

  get '/list/new', auth: :todo_new do
    # TODO: THIS
  end

  post '/list/new', auth: :todo_new do
    # TODO: THIS
  end

  get '/list/:list_id', auth: :user do
    # TODO: THIS
  end

  post '/list/edit/:list_id', auth: :user do
    # TODO: THIS
  end

  get '/list/:list_id/new', auth: :todo_new do
    # TODO: THIS
  end

  post '/list/:list_id/new', auth: :todo_new do
    # TODO: THIS
  end

  post '/list/:list_id/edit/:element_id', auth: :user do
    # TODO: THIS
  end

  get '/delete/:list_id', auth: :todo_delete do
    # TODO: THIS
  end

  get '/delete/:list_id/:element_id', auth: :todo_delete do
    # TODO: THIS
  end
end
