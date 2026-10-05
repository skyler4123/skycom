class Seed::ChatMessageService
  def self.populate!(conversation:, count: 20, image_every: 4)
    members = conversation.chat_users.to_a
    base_time = 2.days.ago

    count.times.map do |i|
      image_position = (i + 1) % image_every == 0
      image_only = image_position && ((i + 1) / image_every).odd?
      with_image = image_position && ((i + 1) / image_every).even?
      timestamp = base_time + i.minutes

      message = conversation.chat_messages.build(
        chat_user: members[i % members.size],
        body: image_only ? nil : Faker::Lorem.sentence,
        created_at: timestamp,
        updated_at: timestamp
      )
      if image_only || with_image
        # NOTE: attaches before save (image-only messages are invalid without
        # an attachment), mirroring Seed::AttachmentService's blob lines.
        # AttachmentService itself can't be reused here — its trailing
        # rails_blob_url call requires a persisted record.
        (image_only ? 2 : 1).times do
          file = File.open(Dir.glob("./faker/images/randoms/*.*").sample)
          file_name, file_type = file.path.split("/").last.split(".")
          message.image_attachments.attach(io: file, filename: file_name, content_type: "image/#{file_type}")
        end
      end
      message.save!
      message
    end
  end
end
