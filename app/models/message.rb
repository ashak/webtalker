class Message < ApplicationRecord
  belongs_to :sender, polymorphic: true, optional: true
  belongs_to :receiver, polymorphic: true, optional: true

  scope :visible_to, ->(user) {
    where(
      receiver: nil
    ).or(
      where(sender: user)
    ).or(
      where(receiver: user)
    )
  }

  after_create_commit -> { broadcast_append_to :talker } if Proc.new { |message| message.receiver.nil? }
  after_create_commit -> { TelnetChannel.broadcast_to 'talker', ApplicationController.renderer.render(partial: 'messages/message_telnet', locals: {message: self}) } if Proc.new { |message| message.receiver.nil? }
end
