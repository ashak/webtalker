class TelnetSessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create update ]
  # rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }
  skip_forgery_protection

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
    else
      return head :unauthorized
    end

    render json: {
      access_token: TelnetAccessToken.issue(user),
      refresh_token: sign_session(Current.session),
      expires_in: 600
    }
  end

  def update
    session = verify_refresh(params[:refresh_token])
    return head :unauthorized unless session

    render json: {
      access_token: TelnetAccessToken.issue(session.user),
      expires_in: 600
    }
  end

  private
    def sign_session(session)
      data = "#{session.id}:#{session.created_at.to_i}"
      sig  = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, data)
      "#{data}.#{sig}"
    end

    def verify_refresh(token)
      data, sig = token.split(".", 2)
      return nil unless sig

      expected = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, data)
      return nil unless ActiveSupport::SecurityUtils.secure_compare(sig, expected)

      session_id, created_at = data.split(":")

      session = Session.find_by(id: session_id)
      return nil unless session
      return nil unless session.created_at.to_i == created_at.to_i

      session
    end
end
