require 'rails_helper'

RSpec.describe SettingGroup, type: :model do
  it_behaves_like "property_mapping concern", SettingGroup
end
