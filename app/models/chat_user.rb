# ChatUser — bridge between the primary-DB User and the chat database.
# One row mirrors one User's display snapshot (display_name/email/avatar_url)
# keyed by the cross-DB pointer `user_id` (plain uuid — cross-DB FKs are
# impossible). Snapshot is written by `sync_from_user!` at seed time and on
# demand; the primary User stays the source of truth.
class ChatUser < Chat
  normalizes :email, with: -> { _1.strip.downcase }

  # --- Associations ---
  # NOTE: explicit inverse_of — ChatConversation/ChatUser each hold multiple
  # has_many associations sharing one foreign key, which defeats Rails
  # automatic inverse detection (ambiguous candidates -> nil inverse).
  has_many :chat_conversation_memberships, foreign_key: :chat_user_id, inverse_of: :chat_user, dependent: :destroy
  has_many :chat_conversations, through: :chat_conversation_memberships
  has_many :sent_messages, class_name: "ChatMessage", foreign_key: :chat_user_id, inverse_of: :chat_user, dependent: :restrict_with_error

  # --- Validations ---
  validates :user_id, presence: true, uniqueness: true
  validates :display_name, :email, presence: true

  def self.sync_from_user!(user)
    chat_user = find_or_initialize_by(user_id: user.id)
    chat_user.assign_attributes(
      display_name: user.name,
      email: user.email,
      avatar_url: user.avatar
    )
    chat_user.save!
    chat_user
  end

  def self.find_by_user(user)
    find_by(user_id: user.id)
  end
end
