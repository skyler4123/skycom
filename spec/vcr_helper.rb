VCR.configure do |config|
  config.cassette_library_dir = 'vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  # config.ignore_localhost = true
  config.ignore_hosts '127.0.0.1', 'localhost'
  config.default_cassette_options = {
    serialize_with: :json
  }
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding == Encoding::BINARY ||
    !http_message.body.valid_encoding?
  end
end

# RSpec.configure do |config|
#   config.around do |example|
#     if example.metadata[:vcr]
#       # VCR.turn_on! { example.run }
#       example.run
#     else
#       VCR.turned_off { example.run }
#     end
#   end
# end
