FactoryBot.define do
  factory :company_migration do
    company
    name { "Import #{SecureRandom.hex(4)}" }
    folder { Folder.create!(company: company, name: name) }
    workflow_status { :draft }
  end
end
