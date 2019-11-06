module ShiftHelper
  def shift_import_fields
    {
      client_name: 'Nombre cliente',
      location_name: 'Nombre estación de trabajo',
      days: 'Días de trabajo',
      holidays: 'Se trabajan feriados',
      type: 'Tipo de trabajo',
      start_date: 'Primer día del turno',
      end_date: 'Último día del turno',
      start_time: 'Hora de inicio',
      end_time: 'Hora de cierre'
    }
  end

  def archive_shift(shift, create_new_shift = true)
    return if shift[:archived]

    DB.transaction do
      if create_new_shift
        new_shift = Shift.new
        Shift.columns.each { |key| new_shift[key] = shift[key] unless %i[id employee_id].include?(key) }
        new_shift[:start_date] = Date.today
        new_shift, new_shift_new_work_hours = get_shift_work_hours(new_shift, new_shift)
        new_shift.save
        new_shift_new_work_hours.each do |wh|
          wh[:shift_id] = new_shift[:id]
          wh.save
        end
      end

      shift[:archived] = true
      shift[:end_date] = Date.today
      shift.save

      check_alert_contract_needs_atention(shift.location)
      unless shift.employee.nil?
        check_alert_2shifts_jointed(shift.employee)
        check_alert_too_many_hours(shift.employee)
      end
      if create_new_shift
        check_alert_contract_needs_atention(new_shift.location)
        check_alert_empty_shift(new_shift)
      end
    end
  end

  def shift_work_amount_at(start_time, end_time, current_hour)
    start_time = "0#{start_time}" if start_time.to_s.length < 5
    end_time = "0#{end_time}" if end_time.to_s.length < 5

    start_hour = start_time.to_s[0..1].to_i
    end_hour = end_time.to_s[0..1].to_i

    # fixes for shifts ending at 00 or more
    if end_hour.zero? || (end_hour < start_hour && current_hour >= start_hour)
      end_hour = 24
    elsif end_hour < start_hour && current_hour <= end_hour
      start_hour = 0
    end

    start_minute = start_time.to_s[3..4].to_i
    end_minute = end_time.to_s[3..4].to_i

    # outside of range
    return 0.0 if current_hour < start_hour || current_hour > end_hour

    # within range
    return 1.0 if current_hour > start_hour && current_hour < end_hour - 1 && end_minute.zero?

    # perfect edge
    return 1.0 if current_hour == start_hour && start_minute.zero?
    return 1.0 if current_hour == end_hour - 1 && end_minute.zero?

    # imperfect edge
    return 1.0 if current_hour > start_hour && current_hour < end_hour && !end_minute.zero?
    return ((60 - start_minute) / 60.0) if current_hour == start_hour
    return (end_minute / 60.0) if current_hour == end_hour

    nil
  end

  def shift_setup(shift, params)
    Shift.columns.each { |key| shift[key] = params[key] if !params[key].nil? && key != :id }

    %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
      shift[day] = (params[day] == 'on' || params[day] == true)
    end

    start_time = params[:start_time].to_s
    start_time = "0#{start_time}" if start_time.length < 5
    shift[:start_time] = start_time

    end_time = params[:end_time].to_s
    end_time = "0#{end_time}" if end_time.length < 5
    shift[:end_time] = end_time

    shift[:includes_holidays] = !(params[:holiday].nil? || params[:holiday] == 0)
    shift[:all_holidays] = false

    if params[:type].is_a?(String)
      shift[:type_id] = JobType.where(type: params[:type]).first[:id]
    end

    shift
  end

  def get_shift_work_hours(shift, params)
    start_time = params[:start_time].to_s
    start_time = "0#{start_time}" if start_time.length < 5
    start_hour = start_time[0..1].to_i

    end_time = params[:end_time].to_s
    end_time = "0#{end_time}" if end_time.length < 5
    end_hour = end_time[0..1].to_i
    end_hour = 23 if end_hour == 0

    shift_work_hours = {}
    shift_hours_sum = 0.0

    days = %i[monday tuesday wednesday thursday friday saturday sunday monday]
    (0..6).each do |day_index|
      day = days[day_index]
      next unless shift[day]

      work_hours_for_this_day = shift_work_hours(day, shift_work_hours, shift)
      if start_hour <= end_hour
        # single day shift
        (0..23).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          shift_hours_sum += work_at_this_hour
        end
        shift_work_hours[day] = work_hours_for_this_day
      elsif end_hour < start_hour
        # mark starting day
        (start_hour..23).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          shift_hours_sum += work_at_this_hour
        end
        shift_work_hours[day] = work_hours_for_this_day

        # mark the next day
        day = days[day_index + 1]
        work_hours_for_this_day = shift_work_hours(day, shift_work_hours, shift)

        # remaining hours
        (0..end_hour).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          shift_hours_sum += work_at_this_hour
        end
        shift_work_hours[day] = work_hours_for_this_day
      end
    end

    shift[:weekly_hours] = shift_hours_sum
    [shift, shift_work_hours.map { |_day, wh| wh }.to_a]
  end

  def shift_matching_dates(shift, start_date, end_date)
    start_date = Date.parse(start_date) unless start_date.is_a? Date
    end_date = Date.parse(end_date) unless end_date.is_a? Date
    holidays = Holiday.where(holiday_date: start_date..end_date).map { |h| h[:holiday_date] }

    matching_dates = []
    return matching_dates if start_date > shift[:end_date]
    return matching_dates if end_date < shift[:start_date]

    (start_date..end_date).each do |date|
      next if date < shift[:start_date]
      next if holidays.include?(date) && !shift[:includes_holidays]
      break if date > shift[:end_date]

      matching_dates << date if shift.days.include?(date_to_week_day(date))
    end

    matching_dates
  rescue ArgumentError => _e
    []
  end

  private

  def shift_work_hours(day, shift_work_hours, shift)
    current_wh_day = shift_work_hours[day.to_sym]
    return current_wh_day unless current_wh_day.nil?

    this_day_on_shift = shift.work_hours.find { |swh| swh[:day_of_week] == day.to_s }
    unless this_day_on_shift.nil?
      (0..23).each { |i| this_day_on_shift["hour_#{i}".to_sym] = 0.0 }
      return this_day_on_shift
    end

    new_work_hour_day = ShiftWorkHours.new
    new_work_hour_day[:day_of_week] = day.to_s
    new_work_hour_day[:shift_id] = shift[:id]
    (0..23).each { |i| new_work_hour_day["hour_#{i}".to_sym] = 0.0 }
    new_work_hour_day
  end
end
