require 'rails_helper'

RSpec.describe NotificationGroup, type: :model do
  it_behaves_like "property_mapping concern", NotificationGroup
end
