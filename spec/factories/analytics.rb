# frozen_string_literal: true

FactoryBot.define do
  factory :analytic do
    company
    name { Analytic::DEFAULT_NAME }
    workflow_status { :active }
    metadata { { "blocks" => Analytic::BLOCKS } }
  end
end
