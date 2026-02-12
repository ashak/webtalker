module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if session = Session.find_by(id: cookies.signed[:session_id])
          self.current_user = session.user
        elsif token = request.headers["X-Telnet-Token"]
          self.current_user = TelnetAccessToken.verify(token)
        end
      end
  end
end
