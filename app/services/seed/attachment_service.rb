class Seed::AttachmentService
  def self.attach(record:, relation: :image_attachments, number: 2)
    (Dir.glob("./faker/images/randoms/*.*").sample(number).map { |dir| File.open(dir) }).each_with_index do |file, index|
      file_name, file_type = file.path.split("/").last.split(".")
      record.send(relation).attach(io: file, filename: file_name, content_type: "image/#{file_type}")
    end
    record.update_avatar if record.class == User
    [ record.send(relation) ].flatten.map { |attachment| Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true) }
  end
end
