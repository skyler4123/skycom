require 'rails_helper'

RSpec.describe StockImport, type: :model do
  it_behaves_like "property_mapping concern", StockImport
end
