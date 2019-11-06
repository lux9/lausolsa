module DocumentHelper
  def document_types
    {
      employee: 'Empleado',
      client: 'Cliente',
      general: 'General'
    }
  end

  def em_document_selectors(text, type)
    text = text.gsub(/XXXXXXXX/, em_document_selector(type))
    text = text.gsub(/XXXX(.+?)XXXX/) { |_m| em_document_selector(type, $1.to_sym) }

    text
  end

  def em_document_markdown(text)
    text = text.gsub(/\r\n|\n/, '&nbsp;<br>')
    Markdown.new(text).to_html
  end

  def em_document_selector(type, selected = nil)
    nav = '<select class="custom-select" style="width:120px;">'
    nav += '<option value="">Se completa al enviar</option>'
    nav += '<option disabled="disabled">Auto-completado por...</option>'

    if type == :employee
      employee_blacklist = %i[worker_union works_holidays]
      nav += employee_import_fields
             .reject { |k, _v| employee_blacklist.include?(k) }
             .sort_by { |_k, v| v }
             .map { |k, v| "<option #{selected == k ? 'selected="selected"' : ''} value='#{k}'>#{v}</option>" }
             .join("\n")
    end
    nav += '</select>'

    nav
  end

  def em_document_clickables_employee(text, employee)
    clickable = '<span class="clickable"><span class="text-primary"><b>(CLICK PARA COMPLETAR)</b></span></span>'
    text = text.gsub(/XXXXXXXX/, clickable)
    text = text.gsub(/XXXX(.+?)XXXX/) { |_m| employee[$1.to_sym] }

    em_document_markdown(text)
  end
end