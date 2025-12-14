require 'rails_helper'

RSpec.describe 'Zeitwerk Autoloader' do
  it 'eager loads all constants without errors' do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end
end
