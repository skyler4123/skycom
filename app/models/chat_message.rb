# ChatMessage — the smallest chat unit. Belongs to a ChatConversation with a
# ChatUser sender who must be a conversation member. Text-only (body),
# image-only (attachments, body blank), or mixed. Attachments live in the
# primary ActiveStorage tables via the polymorphic association.
class ChatMessage < Chat
  include ChatMessage::ImageConcern

  # --- Associations ---
  belongs_to :chat_conversation, inverse_of: :chat_messages
  belongs_to :chat_user, inverse_of: :sent_messages

  # --- Validations ---
  validate :body_or_attachment_present
  validate :sender_must_be_member

  private

  def body_or_attachment_present
    return if body.present? || image_attachments.attached?

    errors.add(:body, "can't be blank without an image")
  end

  def sender_must_be_member
    return if chat_conversation.blank? || chat_user.blank?
    return if chat_conversation.chat_users.include?(chat_user)

    errors.add(:chat_user, "must be a conversation member")
  end
end
