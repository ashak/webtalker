class TelnetChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'telnet:talker'
  end

  def receive(data)
    input = data["message"]
    Message.create!(sender: current_user, content: input) if input
  end
end