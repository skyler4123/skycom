require 'rails_helper'

RSpec.describe 'PostgreSQL Connection' do
  it 'successfully connects to the PostgreSQL database' do
    expect {
      ActiveRecord::Base.connection.execute('SELECT 1')
    }.not_to raise_error
  end
end
