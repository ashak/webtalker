class TelnetAccessToken
  SECRET = Rails.application.secret_key_base

  def self.issue(user)
    payload = {
      user_id: user.id,
      exp: 10.minutes.from_now.to_i
    }

    data = payload.to_json
    sig  = OpenSSL::HMAC.hexdigest("SHA256", SECRET, data)

    Base64.urlsafe_encode64(data) + "." + sig
  end

  def self.verify(token)
    data64, sig = token.split(".", 2)
    return nil unless data64 && sig

    data = Base64.urlsafe_decode64(data64)
    expected = OpenSSL::HMAC.hexdigest("SHA256", SECRET, data)
    return nil unless ActiveSupport::SecurityUtils.secure_compare(sig, expected)

    payload = JSON.parse(data)
    return nil if payload["exp"] < Time.now.to_i

    User.find_by(id: payload["user_id"])
  rescue
    nil
  end
end