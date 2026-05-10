require 'rails_helper'

RSpec.describe 'External Service Connections - Searchkick' do
  describe 'Searchkick Connection' do
    it 'connects to search server successfully' do
      expect { Searchkick.client.ping }.not_to raise_error
      expect(Searchkick.client.ping).to be true
    end
  end
end
