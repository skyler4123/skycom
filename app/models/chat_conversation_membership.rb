# ChatConversationMembership — one member in one group chat.
# Unique per (conversation, user); leaving a conversation destroys the row.
class ChatConversationMembership < Chat
  # --- Associations ---
  belongs_to :chat_conversation, inverse_of: :chat_conversation_memberships
  belongs_to :chat_user, inverse_of: :chat_conversation_memberships

  # --- Validations ---
  validates :chat_user_id, uniqueness: { scope: :chat_conversation_id }
end
