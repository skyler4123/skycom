# config/initializers/storage.rb
Rails.application.config.after_initialize do
  # Ensure Active Storage is configured with an S3 service
  if defined?(ActiveStorage::Blob) && ActiveStorage::Blob.service.respond_to?(:bucket)
    begin
      service = ActiveStorage::Blob.service
      bucket = service.bucket

      unless bucket.exists?
        bucket.create
        Rails.logger.info "[Storage] Bucket '#{bucket.name}' created successfully!"
      else
        Rails.logger.info "[Storage] Bucket '#{bucket.name}' already exists."
      end
    rescue => e
      Rails.logger.warn "[Storage] Could not check or create bucket: #{e.message}"
    end
  end
end
