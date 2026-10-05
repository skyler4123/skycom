# ChatConversation — a group chat. Group-only by design: a 1-1 chat is a
# group of two, so there is no separate DM model. Membership runs through
# ChatConversationMembership; a conversation is created with ≥2 members.
class ChatConversation < Chat
  # --- Associations ---
  # NOTE: explicit inverse_of — see ChatUser for why automatic detection fails here.
  belongs_to :created_by, class_name: "ChatUser", foreign_key: :created_by_chat_user_id, optional: true
  has_many :chat_conversation_memberships, foreign_key: :chat_conversation_id, inverse_of: :chat_conversation, dependent: :destroy
  has_many :chat_users, through: :chat_conversation_memberships
  has_many :chat_messages, foreign_key: :chat_conversation_id, inverse_of: :chat_conversation, dependent: :destroy

  # --- Validations ---
  validate :requires_two_members, on: :create

  private

  def requires_two_members
    return if chat_conversation_memberships.size >= 2

    errors.add(:base, "Conversation must have at least two members")
  end
end
