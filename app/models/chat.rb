# app/models/chat.rb

class Chat < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :chat, reading: :chat }
end
