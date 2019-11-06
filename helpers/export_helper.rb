module ExportHelper
  def export_client_row_titles
    title_row = []
    client_import_fields.each do |key, value|
      break if params[:client_fields].nil? || params[:client_fields].empty?

      title_row << value if params[:client_fields].include?(key.to_s)
    end
    location_import_fields.each do |key, value|
      break if params[:client_location_fields].nil? || params[:client_location_fields].empty?

      title_row << value if params[:client_location_fields].include?(key.to_s)
    end
    shift_import_fields.each do |key, value|
      break if params[:client_shift_fields].nil? || params[:client_shift_fields].empty?

      title_row << value if params[:client_shift_fields].include?(key.to_s)
    end
    client_extra_fields.each do |key, value|
      break if params[:client_extra_fields].nil? || params[:client_extra_fields].empty?

      title_row << value if params[:client_extra_fields].include?(key.to_s)
    end
    title_row
  end

  def export_employee_row_titles
    title_row = []
    employee_import_fields.each do |key, value|
      break if params[:employee_fields].nil? || params[:employee_fields].empty?

      title_row << value if params[:employee_fields].include?(key.to_s)
    end
    shift_import_fields.each do |key, value|
      break if params[:employee_shift_fields].nil? || params[:employee_shift_fields].empty?

      title_row << value if params[:employee_shift_fields].include?(key.to_s)
    end
    employee_extra_fields.each do |key, value|
      break if params[:employee_extra_fields].nil? || params[:employee_extra_fields].empty?

      title_row << value if params[:employee_extra_fields].include?(key.to_s)
    end
    title_row
  end

  def export_client_row(client)
    row_client = []
    client_import_fields.each do |key, _value|
      key = key.to_sym
      break if params[:client_fields].nil?
      next unless params[:client_fields].include?(key.to_s)

      if client[key].nil?
        row_client << ''
        next
      end

      row_client << if client[key].is_a?(TrueClass) || client[key].is_a?(FalseClass)
                      (client[key] ? 'Sí' : 'No')
                    else
                      client[key]
                    end
    end
    row_client
  end

  def export_employee_row(employee)
    row_employee = []
    employee_import_fields.each do |key, _value|
      key = key.to_sym
      break if params[:employee_fields].nil?
      next unless params[:employee_fields].include?(key.to_s)

      if employee[key].nil?
        row_employee << ''
        next
      end

      row_employee << if employee[key].is_a?(TrueClass) || employee[key].is_a?(FalseClass)
                        (employee[key] ? 'Sí' : 'No')
                      else
                        employee[key]
                      end
    end
    row_employee
  end

  def export_client_row_location(location)
    row_location = []
    location_import_fields.each do |key, _value|
      key = key.to_sym
      break if params[:client_location_fields].nil?
      next unless params[:client_location_fields].include?(key)

      if key == :parent_id
        row_location << location.parent.name
        next
      elsif key == :client_id
        row_location << location.client.name
        next
      elsif location[key].nil?
        row_location << ''
        next
      end

      row_location << if location[key].is_a?(TrueClass) || location[key].is_a?(FalseClass)
                        (location[key] ? 'Sí' : 'No')
                      else
                        location[key]
                      end
    end
    row_location
  end

  def export_client_row_shift(shift)
    row_shift = []
    shift_import_fields.each do |key, _value|
      key = key.to_sym
      break if params[:client_shift_fields].nil?
      next unless params[:client_shift_fields].include?(key.to_s)

      if key == :holidays
        row_shift << (shift[:includes_holidays] ? 'Sí' : 'No')
        next
      elsif key == :type
        row_shift << shift.type.type
        next
      elsif key == :days
        row_shift << shift.days.map { |d| date_symbol_to_name(d) }.join(', ')
        next
      elsif %i[client_id client_name].include?(key)
        row_shift << shift.client.name
        next
      elsif %i[location_id location_name].include?(key)
        row_shift << shift.location.full_name
        next
      elsif key == :end_date
        row_shift << (shift[:end_date].to_s == '2099-01-01' ? '' : shift[:end_date])
        next
      elsif shift[key].nil?
        row_shift << ''
        next
      end

      row_shift << if shift[key].is_a?(TrueClass) || shift[key].is_a?(FalseClass)
                     (shift[key] ? 'Sí' : 'No')
                   else
                     shift[key]
                   end
    end
    row_shift
  end

  def export_employee_row_shift(shift)
    row_shift = []
    shift_import_fields.each do |key, _value|
      key = key.to_sym
      break if params[:employee_shift_fields].nil?
      next unless params[:employee_shift_fields].include?(key.to_s)

      if key == :holidays
        row_shift << (shift[:includes_holidays] ? 'Sí' : 'No')
        next
      elsif key == :type
        row_shift << shift.type.type
        next
      elsif %i[client_id client_name].include?(key)
        row_shift << shift.client.name
        next
      elsif %i[location_id location_name].include?(key)
        row_shift << shift.location.full_name
        next
      elsif key == :days
        row_shift << shift.days.map { |d| date_symbol_to_name(d) }.join(', ')
        next
      elsif key == :end_date
        row_shift << (shift[:end_date].to_s == '2099-01-01' ? '' : shift[:end_date])
        next
      elsif shift[key].nil?
        row_shift << ''
        next
      end

      row_shift << if shift[key].is_a?(TrueClass) || shift[key].is_a?(FalseClass)
                     (shift[key] ? 'Sí' : 'No')
                   else
                     shift[key]
                   end
    end
    row_shift
  end

  def export_client_extras(location = nil, shift = nil)
    row_extra = []
    client_extra_fields.each do |key, _value|
      key = key.to_sym
      break if params[:client_extra_fields].nil?
      next unless params[:client_extra_fields].include?(key.to_s)

      row_extra << case key
                   when :shift_absence
                     shift.nil? ? '0' : shift.absences.count
                   when :shift_replacement
                     shift.nil? ? '0' : shift.absences.count { |a| !a.replacement_id.nil? }
                   when :shift_backup
                     location.nil? ? '0' : location.shift_backups.count
                   else
                     ''
                   end
    end
    row_extra
  end

  def export_employee_extras(employee, shift = nil)
    row_extra = []
    employee_extra_fields.each do |key, _value|
      key = key.to_sym
      break if params[:employee_extra_fields].nil?
      next unless params[:employee_extra_fields].include?(key.to_s)

      row_extra << case key
                   when :shift_absence
                     shift.nil? ? employee.shift_absences.count : shift.absences.count
                   when :shift_replacement
                     shift.nil? ? employee.shift_replacements.count : shift.absences.count { |a| a.replacement_id == employee.id }
                   when :shift_backup
                     shift.nil? ? employee.shift_backups.count : employee.shift_backups.count { |sb| sb.client.id == shift.client.id }
                   when :shift_weekly_hours
                     shift.nil? ? 0.0 : shift[:weekly_hours]
                   else
                     ''
                   end
    end
    row_extra
  end
end
