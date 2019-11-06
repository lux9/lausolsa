class DocumentController < ApplicationController
  get '/list/?:current_page?', auth: :user do
    current_page = params[:current_page].nil? ? 1 : params[:current_page].to_i
    page_size = 20
    documents = Document.exclude(id: nil).paginate(current_page, page_size)

    erb :document_list, locals: { menu: [:document],
                                  breadcrumb: [{ url: '/', name: 'Inicio' },
                                               { url: '/document/list', name: 'Documentos' }],
                                  documents: documents,
                                  document_types: { employee: 'Empleado',
                                                    client: 'Cliente',
                                                    general: 'General' } }
  end

  get '/new', auth: :document_new do
    erb :document_new, locals: { menu: [:document],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/document/list', name: 'Documentos' },
                                              { url: '', name: 'Nuevo Documento' }],
                                 document_types: { employee: 'Empleado',
                                                   client: 'Cliente',
                                                   general: 'General' } }
  end

  post '/new', auth: :document_new do
    document = Document.new
    Document.columns.each { |key| document[key] = params[key] if key != :id }
    document[:type] = document_types.key(params[:type])

    if document.valid?
      DB.transaction do
        document.save
        action_log = action_log_simple('Se <strong>cargó</strong> un nuevo documento',
                                       "Documento: <a href='/document/#{document[:id]}'>#{document[:name]}</a>")
        action_log.save
      end

      redirect build_success_url("/document/#{document[:id]}", params[:redir])
    else
      redirect build_error_url('/document/new', params, document.errors)
    end
  end

  get '/edit/:id', auth: :document_new do
    document = Document[params[:id]]
    redirect '/404' if document.nil?

    Document.columns.each { |key| params[key] = document[key] }
    params[:type] = document_types[document[:type].to_sym]

    erb :document_new, locals: { menu: [:document],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/document/list', name: 'Documentos' },
                                              { url: "/document/#{document[:id]}", name: "Documento: #{document[:name]}" }],
                                 document: document }
  end

  post '/edit/:id', auth: :document_new do
    document = Document[params[:id]]
    redirect '/404' if document.nil?

    Document.columns.each { |key| document[key] = params[key] if !params[key].nil? && key != :id }
    document[:type] = document_types.key(params[:type]) unless params[:type].nil?

    if document.valid?
      DB.transaction do
        document.save
        action_log = action_log_simple('Se <strong>modificó</strong> un documento',
                                       "Documento: <a href='/document/#{document[:id]}'>#{document[:name]}</a>")
        action_log.save
      end
      redirect build_success_url '/document/list', params[:redir]
    else
      redirect build_error_url "/document/edit/#{document[:id]}", params, document.errors
    end
  end

  get '/delete/:id', auth: :document_delete do
    document = Document[params[:id]]
    redirect '/404' if document.nil?

    document.delete
    redirect build_success_url '/document/list', params[:redir]
  end

  get '/print/:document_id/employee/:employee_id', auth: :document_employee do
    document = Document[params[:document_id]]
    employee = Employee[params[:employee_id]]
    redirect '/404' if document.nil? || employee.nil?

    breadcrumb = [{ url: '/', name: 'Inicio' },
                  { url: "/employee/#{employee[:id]}", name: employee[:name] },
                  { url: "/document/#{document[:id]}", name: "Documento: #{document[:name]}" }]

    erb :document_printable_employee, layout: :printable, locals: { menu: [:document],
                                                                    breadcrumb: breadcrumb,
                                                                    document: document,
                                                                    employee: employee }
  end

  get '/:id', auth: :user do
    document = Document[params[:id]]
    redirect '/404' if document.nil?

    erb :document_single, locals: { menu: [:document],
                                    breadcrumb: [{ url: '/', name: 'Inicio' },
                                                 { url: '/document/list', name: 'Documentos' },
                                                 { url: '', name: document[:name] }],
                                    document: document }
  end
end
