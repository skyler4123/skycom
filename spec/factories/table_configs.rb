# spec/factories/table_configs.rb
FactoryBot.define do
  factory :table_config do
    association :company
    association :category

    name { "Test table config" }
    resource_name { "products" }

    fields do
      [ { "key" => "name", "label" => "Name", "visible" => true, "sortable" => true,
         "align" => "left", "pinned" => nil, "width" => nil, "roles" => [],
         "is_virtual" => false, "render_config" => {} } ]
    end
  end
end
