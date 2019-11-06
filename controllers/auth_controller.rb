class AuthController < ApplicationController
  get '/' do
    redirect '/' unless @user.nil?
    redirect '/auth/login'
  end

  get '/login' do
    redirect '/' unless @user.nil?
    erb :login, locals: { breadcrumb: [{ url: '', name: 'Iniciar sesión' }] }
  end

  post '/login' do
    redirect '/' unless @user.nil?
    redirect build_success_url('/auth/login?empty=1', "/auth/login?empty=1&redir=#{params[:redir]}") if params[:email].to_s.empty? || params[:password].to_s.empty?

    user_session = session_data_from_password(params[:email], params[:password])
    redirect '/auth/login?failed=1' if user_session.nil?

    session[:user] = user_session
    redirect build_success_url('/', params[:redir])
  end

  post '/token', provides: [:json] do
    halt 400, { 'Content-Type' => 'application/json' }, { message: 'Already logged in', token: user_to_token(@user) }.to_json unless @user.nil?

    if params[:email].to_s.empty? || params[:password].to_s.empty?
      halt 401, { 'Content-Type' => 'application/json' }, { message: 'Login parameters are empty', token: nil }.to_json
    end

    user_session = session_data_from_password(params[:email], params[:password])
    if user_session.nil?
      halt 401, { 'Content-Type' => 'application/json' }, { message: 'Login failed', token: nil }.to_json
    end

    token = user_to_token(user_session)
    halt 200, { 'Content-Type' => 'application/json' }, { message: 'Login OK', token: token }.to_json
  end

  get '/logout' do
    session[:user] = nil
    redirect '/'
  end
end