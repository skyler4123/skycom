require 'rails_helper'

RSpec.describe StockExport, type: :model do
  it_behaves_like "property_mapping concern", StockExport
end
