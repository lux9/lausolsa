class HolidayController < ApplicationController
  get '/list/?:year?', auth: :user do
    year = params[:year].nil? ? Date.today.year : params[:year].to_i
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)
    holidays = Holiday.where { holiday_date >= start_date }.where { holiday_date <= end_date }
    erb :holiday_list, locals: { menu: [:holiday],
                                 breadcrumb: [{ url: '/', name: 'Inicio' },
                                              { url: '/control_panel/list', name: 'Panel de control' },
                                              { url: '/holiday/list', name: 'Feriados' }],
                                 year: year,
                                 holidays: holidays }
  end

  post '/new', auth: :holiday_new do
    date = Date.parse(params[:date]) unless params[:date].nil?
    redirect '/404' if params[:date].nil? || date.nil?

    holiday = Holiday.new
    holiday.holiday_date = date
    holiday.comment = params[:comment] || 'Feriado'

    if holiday.valid?
      DB.transaction do
        holiday.save

        action_log = action_log_simple("Se <strong>cargó</strong> un nuevo feriado el día #{holiday.holiday_date.to_s}")
        action_log.save
      end

      redirect build_success_url("/holiday/list/#{date.year}", params[:redir])
    else
      redirect build_error_url("/holiday/list/#{date.year}", params, holiday.errors)
    end
  end

  post '/delete', auth: :holiday_delete do
    date = Date.parse(params[:date]) unless params[:date].nil?
    redirect '/404' if params[:date].nil? || date.nil?

    holiday = Holiday.where(holiday_date: date)
    holiday.delete unless holiday.nil?

    redirect "/holiday/list/#{date.year}"
  end
end