module ViewHelper
  def link_employee(employee_id)
    return '(Empleado eliminado)' if Employee[employee_id].nil?

    "<a href='/employee/#{employee_id}'>#{Employee[employee_id].full_name}</a>"
  end

  def link_location(location_id)
    return '(Estación de trabajo eliminada)' if Location[location_id].nil?

    "<a href='/location/#{location_id}'>#{Location[location_id].full_name}</a>"
  end

  def link_client(client_id)
    return '(Cliente eliminado)' if Client[client_id].nil?

    "<a href='/client/#{client_id}'>#{Client[client_id].name}</a>"
  end

  def link_user(user_id)
    return '(Usuario eliminado)' if User[user_id].nil?

    User[user_id].name
  end

  def build_query_string(ignore_params = nil)
    if ignore_params.is_a?(Enumerable)
      ignore_params.map { |i| i.to_s }
      return_params = params.find_all { |p| !ignore_params.include?(p[0].to_s) && !p[1].nil? }
    elsif ignore_params.is_a?(String) || ignore_params.is_a?(Symbol)
      return_params = params.find_all { |p| p[0].to_s != ignore_params.to_s && !p[1].nil? }
    else
      return_params = params.find_all { |p| !p[1].nil? }
    end
    return_params.map { |param| "#{param[0]}=#{CGI.escape(param[1])}" }.join('&')
  end

  def em_user_avatar(id)
    File.exist?("public/avatars/#{id}.jpg") ? "/avatars/#{id}.jpg?#{File.mtime("public/avatars/#{id}.jpg").to_i}" : '/default-avatar.jpg'
  end

  def em_client_logo(id)
    File.exist?("public/logos/#{id}.jpg") ? "/logos/#{id}.jpg?#{File.mtime("public/logos/#{id}.jpg").to_i}" : '/icons/client.png'
  end

  def em_file_input(name, pretty_name = name, valid_types = nil, optional = false)
    errors_name = "error_#{name}".to_sym
    errors = params[errors_name] ? JSON.parse(params[errors_name]) : nil

    input = "<label for='input_#{name}'>#{pretty_name} #{'<span class="text-primary">(R)</span>' unless optional}: &nbsp;</label>"
    input += "<input type='file' id='input_#{name}' name='#{name}' value='#{params[name]}' class='form-control "
    input += 'is-invalid ' unless errors.nil?
    input += "' "
    input += "accept='#{valid_types}' " unless valid_types.nil?
    input += 'required ' unless optional
    input += '>'
    input += "<div class='invalid-feedback'>#{errors.join("<br>\r\n")}</div>" unless errors.nil?
    input += '<br>'

    input
  end

  def em_input(type, name, pretty_name = name, placeholder = '', optional = false)
    errors_name = "error_#{name}".to_sym
    errors = params[errors_name] ? JSON.parse(params[errors_name]) : nil

    input = ''
    input += "<label for='input_#{name}'>#{pretty_name} #{'<span class="text-primary">(R)</span>' unless optional}: &nbsp;</label>" unless pretty_name == ''
    input += "<input type='#{type}' id='input_#{name}' name='#{name}' value='#{params[name]}' class='form-control "
    input += 'is-invalid ' unless errors.nil?
    input += "' placeholder='#{placeholder}' #{'required ' unless optional}>"
    input += "<div class='invalid-feedback'>#{errors.join("<br>\r\n")}</div>" unless errors.nil?
    input += '<br>'

    input
  end

  def em_checkbox(name, label, optional = false)
    errors_name = if params["error_#{name}".to_sym].nil?
                    "error_#{name[/(.*)_(.*)/, 1]}".to_sym
                  else
                    "error_#{name}".to_sym
                  end
    errors = params[errors_name] ? JSON.parse(params[errors_name]) : nil

    checked = params[name] == 'on' ? 'checked="checked"' : ''
    input = "<div class='form-check'>"
    input += "<input type='checkbox' #{checked} id='checkbox_#{name}' name='#{name}' class='form-check-input "
    input += 'is-invalid ' unless errors.nil?
    input += optional ? "'>" : "' required>"
    input += " <label for='checkbox_#{name}' class='form-check-label'> #{label}</input></label>"
    input += "<div class='invalid-feedback'>#{errors.join("\r\n")}</div>" unless errors.nil?
    input += '</div>'

    input
  end

  def em_radio(name, value, label, optional = false)
    errors_name = "error_#{name}_#{value}".to_sym
    errors = params[errors_name] ? JSON.parse(params[errors_name]) : nil

    checked = params[name.to_sym] == value ? 'checked="checked"' : ''
    input = "<div class='form-check'>"
    input += "<input type='radio' #{checked} id='radio_#{name}_#{value}' name='#{name}' value='#{value}' class='form-check-input "
    input += 'is-invalid ' unless errors.nil?
    input += optional ? "'>" : "' required>"
    input += " <label for='radio_#{name}_#{value}' class='form-check-label'> #{label}</input></label>"
    input += "<div class='invalid-feedback'>#{errors.join("\r\n")}</div>" unless errors.nil?
    input += '</div>'

    input
  end

  def em_select(name, label, list, optional = false)
    errors_name = "error_#{name}".to_sym
    errors = params[errors_name] ? JSON.parse(params[errors_name]) : nil

    input = "<div class='form-group'>"
    input += "<label for='select_#{name}'>#{label} <span class='text-primary'>(R)</span>: &nbsp;</label>" unless label == ''
    input += "<select class='custom-select' id='select_#{name}' name='#{name}'"
    input += optional ? "'>" : "' required>"
    input += "<option selected='selected' disabled='disabled'></option>" if list.nil? || list.empty?
    list.each { |element| input += "<option #{params[name] == element ? 'selected=selected' : ''}>#{element}</option>" }
    input += '</select>'
    input += "<div class='invalid-feedback'>#{errors.join("\r\n")}</div>" unless errors.nil?
    input += '</div>'

    input
  end

  def em_provincias(name, label)
    provincias = ['Ciudad Autónoma de Buenos Aires', 'Buenos Aires', 'Catamarca',
                  'Chaco', 'Chubut', 'Córdoba', 'Corrientes', 'Entre Ríos',
                  'Formosa', 'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza', 'Misiones',
                  'Neuquén', 'Río Negro', 'Salta', 'San Juan', 'Santa Cruz',
                  'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego', 'Tucumán']
    em_select(name, label, provincias)
  end

  def em_countries(name, label)
    countries = ['Argentina']
    em_select(name, label, countries)
  end

  def em_pagination(url_prefix, current_page, page_count, page_delta = 5)
    params_joined = params.find_all { |param| !%w[current_page id].include? (param[0]).to_s }
                          .map { |param| "#{param[0]}=#{param[1]}" }.join('&')
    pagination = '<div class="text-center mx-auto">' \
                 '  <nav style="display: inline-block" aria-label="pagination"><ul class="pagination">' \
                 "    <li class='page-item #{current_page == 1 ? 'disabled' : ''}'>" \
                 "      <a class='page-link' href='#{url_prefix}#{current_page - 1}?#{params_joined}' tabindex='-1'>Previous</a>" \
                 '    </li>'
    first_page = [current_page - page_delta, 1].max
    last_page = [current_page + page_delta, page_count].min
    if first_page > 1
      pagination += em_pagination_page(url_prefix, 1, current_page)
      pagination += '<li class="page-item disabled"><a class="page-link" href="#">...</a></li>' if first_page - 1 > 1
    end
    (first_page..last_page).each do |page|
      pagination += em_pagination_page(url_prefix, page, current_page)
    end
    if last_page < page_count
      pagination += '<li class="page-item disabled"><a class="page-link" href="#">...</a></li>' if last_page + 1 < page_count
      pagination += em_pagination_page(url_prefix, page_count, current_page)
    end
    pagination += "    <li class='page-item #{current_page == page_count ? 'disabled' : ''}'>" \
                  "      <a class='page-link' href='#{url_prefix}#{current_page + 1}?#{params_joined}'>Next</a>" \
                  '    </li></ul></nav></div>'
    pagination
  end

  def em_pagination_page(url_prefix, page, current_page)
    params_joined = params.find_all { |param| !%w[current_page id].include? (param[0]).to_s }
                          .map { |param| "#{param[0]}=#{param[1]}" }.join('&')
    "<li class='page-item #{page == current_page ? 'active' : ''}'><a class='page-link' href='#{url_prefix}#{page}?#{params_joined}'>#{page}</a></li>"
  end

  def location_breadcrumbs(location, current_url = false)
    breadcrumbs = [{ url: '/', name: 'Inicio' },
                   { url: '/client/list', name: 'Clientes' }]

    if location.nil?
      breadcrumbs << { url: "/client/#{params[:client_id]}", name: Client[params[:client_id]].name }
      return breadcrumbs
    else
      breadcrumbs << { url: "/client/#{location.client.id}", name: location.client.name }
    end

    unless location.parent.nil?
      parent_location = location.parent
      location_breadcrumbs = []
      until parent_location.nil?
        location_breadcrumbs << parent_location
        parent_location = parent_location.parent
      end
      location_breadcrumbs.reverse_each do |location_breadcrumb|
        breadcrumbs << { url: "/location/#{location_breadcrumb.id}", name: location_breadcrumb.name }
      end
    end

    breadcrumbs << if current_url
                     { url: "/location/#{location.id}", name: location.name }
                   else
                     { url: '', name: location.name }
                   end

    breadcrumbs
  end

  def human_readable_date(date, start_time=nil, end_time=nil)
    result = "#{date_to_dayname(date)} #{date.mday} de #{date_to_monthname(date)}"
    result += " de #{start_time.to_s[0..4]} a #{end_time.to_s[0..4]}" unless start_time.nil?
    result
  end

  def shift_holiday_label(shift)
    shift[:includes_holidays] ? '<strong>(incluye feriados)</strong>' : ''
  end

  def shift_readable_dates(shift)
    dates = ''
    if shift.monday
      dates += 'Lunes'
      if shift.tuesday
        dates += ' a '
      elsif shift.wednesday || shift.thursday || shift.friday || shift.saturday || shift.sunday
        dates += ', '
      end
    end

    if shift.tuesday && (!shift.monday || !shift.wednesday)
      dates += 'Martes'
      if shift.wednesday
        dates += ' a '
      elsif shift.thursday || shift.friday || shift.saturday || shift.sunday
        dates += ', '
      end
    end

    if shift.wednesday && (!shift.tuesday || !shift.thursday)
      dates += 'Miércoles'
      if shift.thursday
        dates += ' a '
      elsif shift.friday || shift.saturday || shift.sunday
        dates += ', '
      end
    end

    if shift.thursday && (!shift.wednesday || !shift.friday)
      dates += 'Jueves'
      if shift.friday
        dates += ' a '
      elsif shift.saturday || shift.sunday
        dates += ', '
      end
    end

    if shift.friday && (!shift.thursday || !shift.saturday)
      dates += 'Viernes'
      if shift.saturday
        dates += ' a '
      elsif shift.sunday
        dates += ', '
      end
    end

    if shift.saturday && (!shift.friday || !shift.sunday)
      dates += 'Sábados'
      dates += ' a ' if shift.sunday
    end

    dates += 'Domingos' if shift.sunday

    dates = dates.gsub(/(.*), (.*)/, '\1 y \2')
    dates + " de #{shift.start_time.to_s[0..4]} a #{shift.end_time.to_s[0..4]}"
  end

  def employee_shift_details(employee)
    details = ''

    if employee.shifts.count > 0
      details += "Turnos asignados: #{employee.shifts.count} <a href='#' id='#{employee.id}_shifts_toggle'>(ver detalle)</a><br>"
      details += "<ul id='#{employee.id}_shifts' style='display: none'>"
      employee.shifts.each do |shift|
        details += "<li>#{shift.client.name} - #{shift.location.full_name} - #{shift.type.type}<br>#{shift_readable_dates(shift)}</li>"
      end
      details += '</ul>'
      details += "<script>$('##{employee.id}_shifts_toggle').click(function(event) { event.preventDefault(); $('ul##{employee.id}_shifts').toggle(); });</script>"
    end

    next_replacements = employee.shift_replacements.reject { |s| s.absence_date < Date.today }
    if next_replacements.count > 0
      details += "Suplencias pendientes: #{next_replacements.count} <a href='#' id='#{employee.id}_replacements_toggle'>(ver detalle)</a><br>"
      details += "<ul id='#{employee.id}_replacements' style='display: none'>"
      next_replacements.each do |replacement|
        details += '<li>' \
                   "#{human_readable_date(replacement.absence_date, replacement.shift.start_time, replacement.shift.end_time)} - " \
                   "#{replacement.shift.client.name} - #{replacement.shift.location.full_name} - #{replacement.shift.type.type}" \
                   '</li>'
      end
      details += '</ul>'
      details += "<script>$('##{employee.id}_replacements_toggle').click(function(event) { event.preventDefault(); $('ul##{employee.id}_replacements').toggle(); });</script>"
    end

    if employee.shifts.count.zero? && next_replacements.count.zero?
      details += '<strong>El empleado no tiene turnos o suplencias a cargo</strong><br>'
    end

    unless employee.comment.nil? || employee.comment.empty?
      details += "Comentario: #{employee.comment}<br>"
    end

    details
  end

  def date_to_week_day(date)
    %i[monday tuesday wednesday thursday friday saturday sunday][date.cwday - 1]
  end

  def date_to_dayname(date)
    %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado][date.wday]
  end

  def date_symbol_to_name(sym_date)
    case sym_date.to_sym
    when :sunday
      'Domingo'
    when :saturday
      'Sábado'
    when :friday
      'Viernes'
    when :thursday
      'Jueves'
    when :wednesday
      'Miércoles'
    when :tuesday
      'Martes'
    when :monday
      'Lunes'
    else
      ''
    end
  end

  def date_day_name_to_symbol(day_name)
    case day_name.to_s
    when 'Domingo'
      :sunday
    when 'Sábado'
      :saturday
    when 'Viernes'
      :friday
    when 'Jueves'
      :thursday
    when 'Miércoles'
      :wednesday
    when 'Martes'
      :tuesday
    when 'Lunes'
      :monday
    end
  end

  def date_to_monthname(date)
    %w[N/A Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre][date.mon]
  end

  def holiday_calendar(holidays, year, month)
    calendar = "<p class='text-center'><strong>#{date_to_monthname(Date.new(year, month, 1))} #{year}</strong></p>"
    calendar += '<table class="table table-sm table-condensed">'
    # Header
    calendar += '<thead>'
    calendar += '<tr>'
    %w[Lun Mar Mie Jue Vie Sab Dom].each { |day| calendar += "<th class='text-center' scope='col'>#{day}</th>" }
    calendar += '</tr>'
    calendar += '</thead>'
    # Dates
    calendar += '<tbody>'
    # Weeks
    first_week = Date.new(year, month, 1).cweek
    last_week = Date.new(year, month, -1).cweek
    if last_week != 1 && first_week < 49
      weeks = (first_week..last_week).map { |w| { year: year, week: w } }
    elsif last_week == 1
      weeks = (first_week..first_week + 4).map { |w| { year: year, week: w } }
      weeks << { year: year + 1, week: last_week }
    else
      weeks = (1..last_week).map { |w| { year: year, week: w } }
      weeks.unshift(year: year - 1, week: first_week)
    end
    weeks.each do |this_week|
      calendar += '<tr>'
      (1..7).each do |day_n|
        current_day = Date.commercial(this_week[:year], this_week[:week], day_n)
        if current_day.month != month
          calendar += "<td scope='row'>&nbsp;</td>"
        else
          holiday_today = holidays.find { |h| h.holiday_date == current_day }
          if holiday_today.nil?
            shift_color = ''
            tooltip_html = ''
            if user_matches_type(:holiday_new)
              current_day_html = "<a href='#' class='text-dark' id='holiday_#{current_day.to_s}' data-toggle='modal' data-target='#newHoliday'>#{current_day.day}</a>"
            else
              current_day_html = current_day.day
            end
          else
            shift_color = 'bg-info text-white'
            tooltip_html = "data-toggle='tooltip' data-html='true' data-placement='bottom' title='<span class=\"small\">#{holiday_today.comment}</span>'"
            if user_matches_type(:holiday_delete)
              current_day_html = "<a href='#' class='text-white' id='remove_holiday_#{current_day.to_s}'>#{current_day.day}</a>"
            else
              current_day_html = current_day.day
            end
          end
          calendar += "<td scope='row' #{tooltip_html}class='text-center #{shift_color} #{current_day.month != month ? 'text-white' : ''}'>#{current_day_html}</td>"
        end
      end
      calendar += '</tr>'
    end
    calendar += '</tbody>'
    calendar += '</table>'
    calendar
  end

  def employee_calendar(employee, year, month)
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)

    previous_month = start_date - 2
    previous_month = Date.new(previous_month.year, previous_month.month, 1)
    next_month = end_date + 2
    next_month = Date.new(next_month.year, next_month.month, 1)

    calendar = "<div class='container mb-2'>"
    calendar += "<div class='row mx-0 px-0'>"
    calendar += "<div class='col-1 mx-0 px-0 text-left'><a class='btn btn-success' href='?starting_date=#{previous_month.to_s}'>&lt;</a></div>"
    calendar += "<div class='col-10 mx-0 px-0 text-center'><strong>#{date_to_monthname(start_date)} #{year}</strong></div>"
    calendar += "<div class='col-1 mx-0 px-0 text-right'><a class='btn btn-success' href='?starting_date=#{next_month.to_s}'>></a></div>"
    calendar += '</div></div>'
    calendar += '<table class="table table-sm table-condensed">'
    # Header
    calendar += '<thead>'
    calendar += '<tr>'
    %w[Lun Mar Mie Jue Vie Sab Dom].each { |day| calendar += "<th class='text-center mx-0 px-1' scope='col'>#{day}</th>" }
    calendar += '</tr>'
    calendar += '</thead>'
    # Dates
    calendar += '<tbody>'
    # Weeks
    first_week = start_date.cweek
    last_week = end_date.cweek
    # Holidays
    holidays = Holiday.where(holiday_date: start_date..end_date)
    # Fix first/last week starting day
    if last_week != 1 && first_week < 49
      weeks = (first_week..last_week).map { |w| { year: year, week: w } }
    elsif last_week == 1
      weeks = (first_week..first_week + 4).map { |w| { year: year, week: w } }
      weeks << { year: year + 1, week: last_week }
    else
      weeks = (1..last_week).map { |w| { year: year, week: w } }
      weeks.unshift(year: year - 1, week: first_week)
    end
    weeks.each do |this_week|
      calendar += '<tr>'
      (1..7).each do |day_n|
        current_day = Date.commercial(this_week[:year], this_week[:week], day_n)
        if current_day.month != month
          calendar += "<td scope='row'>&nbsp;</td>"
        else
          shift_color, tooltip_info = calendar_color_and_tooltip(employee, current_day, holidays)
          if tooltip_info.nil? || tooltip_info == ''
            tooltip_html = ''
          else
            tooltip_html = "data-toggle='tooltip' data-html='true' data-placement='bottom' title='<span class=\"small\">#{tooltip_info}</span>'" unless tooltip_info.nil?
          end
          calendar += "<td scope='row' #{tooltip_html}class='text-center #{shift_color} #{current_day.month != month ? 'text-white' : ''}'>#{current_day.day}</td>"
        end
      end
      calendar += '</tr>'
    end
    calendar += '</tbody>'
    calendar += '</table>'
    calendar
  end

  def calendar_tooltip_shift(shift)
    "#{shift.client.name} - #{shift.location.full_name}<br>" \
    "Turno ##{shift.id} - #{shift.start_time.to_s[0, 5]} - #{shift.end_time.to_s[0, 5]}"
  end

  def calendar_tooltip_absence(absence)
    '<strong>Ausencia a turno</strong><br>' \
    "#{absence.client.name} - #{absence.location.full_name}<br>" \
    "Turno ##{absence.shift.id} - #{absence.shift.start_time.to_s[0, 5]} - #{absence.shift.end_time.to_s[0, 5]}<br>" \
    "#{absence.replacement_id.nil? ? '<strong>Sin suplente asignado</strong>' : "Suplente: #{absence.replacement_employee.name}"}"
  end

  def calendar_tooltip_replacement(replacement)
    '<strong>Suplencia de turno</strong><br>' \
    " #{replacement.client.name} - #{replacement.location.full_name}<br>" \
    "Turno ##{replacement.shift.id} - #{replacement.shift.start_time.to_s[0, 5]} - #{replacement.shift.end_time.to_s[0, 5]}<br>" \
    "Suplencia de #{replacement.absent_employee.name}"
  end

  def calendar_tooltip_unavailable(employee_absence)
    '<strong>No disponible</strong><br>' \
    "Motivo: #{employee_absence.reason}"
  end

  def calendar_tooltip_holiday(holiday, workday = false)
    (workday ? '<strong>Feriado laborable</strong>' : '<strong>Día no laborable</strong>') + \
    "<br>#{holiday.comment}"
  end

  def calendar_color_and_tooltip(employee, current_day, holidays)
    shift_color = []
    tooltip_info = []

    holiday_today = holidays.find { |h| h[:holiday_date] == current_day }
    absences_today = employee.shift_absences.find_all { |a| a.absence_date == current_day }
    employee_absence_today = employee.employee_absences.find { |a| (a.absence_start_date <= current_day && a.absence_end_date >= current_day) }
    replacements_today = employee.shift_replacements.find_all { |a| a.absence_date == current_day }
    shifts_today = employee.shifts.find_all { |s| shift_matching_dates(s, current_day, current_day).any? }

    unless holiday_today.nil?
      shift_color << 'font-weight-bold'
      tooltip_info << calendar_tooltip_holiday(holiday_today,
                                               (shifts_today.any? { |s| s[:includes_holidays] }))
    end

    if !absences_today.to_a.empty?
      absences_today.each do |absence|
        shift_color << (absences_today.any? { |a| a.replacement_id.nil? } ? 'bg-danger text-white' : 'bg-warning')
        tooltip_info << calendar_tooltip_absence(absence)
      end
    elsif !employee_absence_today.nil?
      shift_color << 'bg-secondary'
      tooltip_info << calendar_tooltip_unavailable(employee_absence_today)
    elsif shifts_today != []
      shifts_today.each do |shift|
        shift_color << 'bg-success text-white'
        tooltip_info << calendar_tooltip_shift(shift)
      end
    elsif replacements_today != []
      replacements_today.each do |replacement|
        shift_color << 'bg-info text-white'
        tooltip_info << calendar_tooltip_replacement(replacement)
      end
    end

    [shift_color.join(' '), tooltip_info.join('<br>&nbsp;<br>')]
  end

  def calendar_reference
    reference  = '<span class="badge badge-success text-white font-weight-normal">&nbsp;1&nbsp;</span> Jornada asignada<br>'
    reference += '<span class="badge badge-danger text-white font-weight-normal">&nbsp;1&nbsp;</span> Ausencia sin cubrir<br>'
    reference += '<span class="badge badge-info text-white font-weight-normal">&nbsp;1&nbsp;</span> Suplencia de otro empleado<br>'
    reference += '<span class="badge badge-warning font-weight-normal">&nbsp;1&nbsp;</span> Ausencia con suplente<br>'
    reference += '<span class="badge badge-secondary text-dark font-weight-normal">&nbsp;1&nbsp;</span> Período no disponible<br>'
    reference += '<span class="badge font-weight-bold">&nbsp;1&nbsp;</span> Día feriado (negrita)<br>'
    reference
  end

  def date_is_holiday(date)
    Holiday.where(holiday_date: date).count.zero? ? '<strong>(feriado)</strong>' : ''
  end

  def trim(num)
    i = num.to_i
    f = num.to_f
    i == f ? i : f
  end
end
