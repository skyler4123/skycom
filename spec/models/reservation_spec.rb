require 'rails_helper'

RSpec.describe Reservation, type: :model do
  it_behaves_like "property_mapping concern", Reservation
end
