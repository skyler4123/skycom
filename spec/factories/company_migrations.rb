FactoryBot.define do
  factory :company_migration do
    company
    name { "Import #{SecureRandom.hex(4)}" }
    folder { Folder.create!(company: company, name: "Import #{SecureRandom.hex(3)}") }
  end
end
