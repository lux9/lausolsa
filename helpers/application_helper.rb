module ApplicationHelper
  def menu_elements
    [
      { link: '/client/list', title: 'Clientes', icon: '/icons/client.png' },
      { link: '/employee/list', title: 'Empleados', icon: '/icons/employee.png' },
      { link: '/document/list', title: 'Documentos', icon: '/icons/document.png' },
      { link: '/alert/list', title: 'Alertas', icon: '/icons/log.png' },
      { link: '#" data-toggle="modal" data-target="#quickActionsModal', title: 'Acciones rápidas', icon: '/icons/quick-actions.png' },
      { link: '/control_panel/list', title: 'Panel de control', icon: '/icons/control-panel.png' }
    ]
  end

  def time_difference(time_start, time_end)
    unless time_start.is_a?(Sequel::SQLTime)
      time_start = Sequel::SQLTime.parse(time_start)
    end
    unless time_end.is_a?(Sequel::SQLTime)
      time_end = Sequel::SQLTime.parse(time_end)
    end

    return 0 if time_start == time_end

    # Fix for time_end == 00:00
    if time_end == Sequel::SQLTime.create(0, 0, 0)
      time_end = Sequel::SQLTime.create(23, 59, 59)
    end

    time_diff = (time_end - time_start).round
    time_diff += 1 if ((time_diff + 1) % 3600).zero?

    time_diff
  end

  def seconds_to_time(seconds)
    return nil unless seconds.is_a?(Numeric)

    seconds = seconds.to_i
    Sequel::SQLTime.parse(Time.at(seconds).utc.strftime('%H:%M:%S'))
  end

  # @param [String] cuit
  def validate_cuit(cuit)
    return false if cuit.length != 13 || cuit[2] != '-' || cuit[11] != '-'

    # digito verificador
    base = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2]
    cuit_int = cuit.delete('-')
    sum = 0
    (0..9).each { |i| sum += (cuit_int[i]).to_i * base[i] }
    aux = 11 - (sum % 11).to_i

    return cuit[12].to_i.zero? if aux == 11
    return cuit[12].to_i == 9 if aux == 10
    return true if cuit[12].to_i == aux

    false
  end

  def build_success_url(url, redir_url = nil)
    # params[:redir] is set and it's an URI
    if !redir_url.nil? && redir_url != '' && redir_url[0] != 'h' && redir_url[0] == '/'
      return redir_url
    end

    # otherwise, the default URL
    url
  end

  def build_error_url(url, params, errors)
    errors = errors.map do |error|
      if error[0].is_a?(Array)
        error[0].map { |e| "error_#{e}=#{error[1]}" }.join('&')
      else
        "error_#{error[0]}=#{error[1]}"
      end
    end.join('&')
    "#{url}?invalid=1&#{errors}&#{build_query_string}"
  end

  def initialize_work_hours
    Shift.each do |shift|
      shift = shift_setup(shift, shift)
      shift.save if shift.valid?

      shift, shift_new_work_hours = get_shift_work_hours(shift, shift)
      shift.save if shift.valid?

      shift.work_hours.each { |swh| unless shift_new_work_hours.include? swh
                                      swh.delete
                                    end }
      shift_new_work_hours.each { |swh| swh.save if swh.valid? }
    end
    Employee.each do |employee|
      if employee.available_hours.nil? || employee.available_hours.empty?
        available_hours = employee_default_available_hours(employee)
        available_hours.values.each { |ah| ah.save if ah.valid? }
      end
    end
    nil
  end
end
