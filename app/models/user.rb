class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sent_messages, as: :sender, class_name: "Message"
  has_many :received_messages, as: :receiver, class_name: "Message"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def messages
    Message.visible_to(self)
  end
end
