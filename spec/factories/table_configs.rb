# spec/factories/table_configs.rb
FactoryBot.define do
  factory :table_config do
    association :company
    association :category
    association :property_mapping

    name { "Test table config" }
    resource_name { "products" }

    metadata do
      { "columns" => [ { "key" => "name", "name" => "Name", "visible" => true,
         "align" => "left", "width" => nil } ] }
    end
  end
end
