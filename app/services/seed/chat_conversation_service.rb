class Seed::ChatConversationService
  DEFAULT_PLAN = [ 2, 2, 3, 4, 5, 6 ].freeze

  def self.create_groups!(chat_users:, plan: DEFAULT_PLAN)
    plan.each_with_index.map do |size, index|
      members = chat_users.sample(size)
      conversation = ChatConversation.new(
        title: index % 3 == 2 ? nil : Faker::Lorem.words(number: 3).join(" "),
        created_by: members.first
      )
      members.each { |member| conversation.chat_conversation_memberships.build(chat_user: member) }
      conversation.save!
      conversation
    end
  end
end
