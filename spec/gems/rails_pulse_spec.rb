# require 'rails_helper'

# RSpec.describe 'RailsPulse' do
#   it 'is configured and enabled' do
#     expect(RailsPulse.configuration.enabled).to be true
#   end

#   it 'connects to the rails_pulse database' do
#     expect {
#       RailsPulse::ApplicationRecord.connection.execute('SELECT 1')
#     }.not_to raise_error
#   end

#   it 'is mounted in application routes' do
#     routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
#     expect(routes).to include('/rails_pulse')
#   end
# end
