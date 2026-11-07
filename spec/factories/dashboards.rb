# frozen_string_literal: true

FactoryBot.define do
  factory :dashboard do
    company
    name { Dashboard::DEFAULT_NAME }
    workflow_status { :active }
    metadata { { "blocks" => Dashboard::BLOCKS } }
  end
end
