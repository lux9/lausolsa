module AbsenceHelper
  def employee_absence_contains_dates(employee_absence, dates)
    start_date = employee_absence.absence_start_date
    end_date = employee_absence.absence_end_date
    dates.any? { |date| start_date <= date && end_date >= date }
  end
end
