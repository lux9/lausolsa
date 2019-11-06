module AuthHelper
  def user_matches_type(type)
    type = type.to_sym

    return false if @user.nil?
    return true if type == :user

    !@user[:privileges].nil? && @user[:privileges][type] == true
  end

  def auth_token_secret
    'EnEl2doSemestrePasaronCosas'
  end

  def user_to_token(user)
    JWT.encode [user[:id], user[:email]], auth_token_secret
  end

  def session_data_from_password(email, password)
    user = User[email: email]
    return nil if user.nil?

    user = user.authenticate(password)
    return nil if user.nil?

    user[:privileges] = em_role_privileges_to_hash(user.role[:privileges])
    user # return
  end

  def session_data_from_token(auth_token)
    return nil if auth_token.nil? || auth_token.empty?

    begin
      id, email = JWT.decode auth_token, auth_token_secret
    rescue JWT::DecodeError
      return nil
    end

    user_email = User[email]
    user_id = User[id]

    if user_id.nil? || user_email.nil? || user_id[:id] != user_email[:id]
      return nil
    end

    user_id[:privileges] = em_role_privileges_to_hash(user_id.role[:privileges])
    user_id # return
  end
end
