# frozen_string_literal: true

FactoryBot.define do
  factory :import do
    company
    name { "Import #{SecureRandom.hex(4)}" }
    folder { Folder.create!(company: company, name: name) }
    creator { association :employee, company: company }
    workflow_status { :draft }
  end
end
