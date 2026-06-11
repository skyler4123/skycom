# spec/system/kredis_connection_spec.rb
require 'rails_helper'

RSpec.describe 'Kredis Connection', type: :system do
  it 'successfully connects to the Redis server backend' do
    expect {
      Kredis.redis.ping
    }.not_to raise_error

    expect(Kredis.redis.ping).to eq("PONG")
  end

  it 'successfully sets and gets a basic data key wrapper lifecycle' do
    # 1. Initialize an isolated string instance key
    test_key = Kredis.string("rspec_health_check_key")

    expect {
      # 2. Test writing data directly to memory
      test_key.value = "Kredis is working!"
    }.not_to raise_error

    # 3. Test reading the data back out of memory
    expect(test_key.value).to eq("Kredis is working!")

    # 4. Clean up after the test completes
    test_key.clear
    expect(test_key.value).to be_nil
  end
end
