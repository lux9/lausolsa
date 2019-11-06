module ShiftBackupHelper
  def shift_backup_setup(shift_backup, params)
    ShiftBackup.columns.each { |key| shift_backup[key] = params[key] if !params[key].nil? && key != :id }

    shift_backup[:start_time] = params[:start_time] unless params[:start_time].nil?
    shift_backup[:end_time] = params[:end_time] unless params[:end_time].nil?
    shift_backup[:hours] = 0.0

    if params[:type].is_a?(String)
      shift_backup[:type_id] = JobType.where(type: params[:type]).first[:id]
    end

    shift_backup
  end

  def get_shift_backup_work_hours(shift_backup, params)
    start_time = params[:start_time].to_s
    start_time = "0#{start_time}" if start_time.length < 5
    start_hour = start_time[0..1].to_i

    end_time = params[:end_time].to_s
    end_time = "0#{end_time}" if end_time.length < 5
    end_hour = end_time[0..1].to_i
    end_hour = 23 if end_hour == 0

    sb_work_hours = {}
    sb_hours_sum = 0.0

    days = %i[monday tuesday wednesday thursday friday saturday sunday monday]
    (0..6).each do |day_index|
      day = days[day_index]
      next unless date_to_week_day(shift_backup[:date]) == day

      work_hours_for_this_day = get_day_from_shift_backup_work_hours(day, sb_work_hours, shift_backup)
      if start_hour < end_hour
        # single day shift
        (0..23).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          sb_hours_sum += work_at_this_hour
        end
        sb_work_hours[day] = work_hours_for_this_day
      elsif end_hour < start_hour
        # mark starting day
        (start_hour..23).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          sb_hours_sum += work_at_this_hour
        end
        sb_work_hours[day] = work_hours_for_this_day

        # mark the next day
        day = days[day_index + 1]
        work_hours_for_this_day = get_day_from_shift_backup_work_hours(day, sb_work_hours, shift_backup)

        # remaining hours
        (0..end_hour).each do |current_hour|
          work_at_this_hour = shift_work_amount_at(start_time, end_time, current_hour)
          work_hours_for_this_day["hour_#{current_hour}".to_sym] = work_at_this_hour
          sb_hours_sum += work_at_this_hour
        end
        sb_work_hours[day] = work_hours_for_this_day
      end

      # shift backups have a single date
      break
    end

    shift_backup[:hours] = sb_hours_sum
    [shift_backup, sb_work_hours.map { |_day, wh| wh }.to_a]
  end

  private

  def get_day_from_shift_backup_work_hours(day, sb_work_hours, shift_backup)
    current_wh_day = sb_work_hours[day.to_sym]
    return current_wh_day unless current_wh_day.nil?

    this_day_on_shift_backup = shift_backup.work_hours.find { |swh| swh[:day_of_week] == day.to_s }
    unless this_day_on_shift_backup.nil?
      (0..23).each { |i| this_day_on_shift_backup["hour_#{i}".to_sym] = 0.0 }
      return this_day_on_shift_backup
    end

    new_work_hour_day = ShiftBackupWorkHours.new
    new_work_hour_day[:day_of_week] = day.to_s
    new_work_hour_day[:shift_backup_id] = shift_backup[:id]
    (0..23).each { |i| new_work_hour_day["hour_#{i}".to_sym] = 0.0 }
    new_work_hour_day
  end
end
