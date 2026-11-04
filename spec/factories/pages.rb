# spec/factories/pages.rb
FactoryBot.define do
  factory :page do
    association :company

    transient do
      branch { nil }
    end

    page_type { :pos }
    resolution { :desktop }
    name { "#{page_type.to_s.humanize} Page" }
    code { "PG-#{SecureRandom.hex(4).upcase}" }
    metadata { { "roles" => [] } }
    lifecycle_status { :active }
    workflow_status { :approved }

    initialize_with do
      Page.find_or_initialize_by(
        company: company,
        page_type: page_type,
        resolution: resolution
      ).tap do |record|
        if record.new_record?
          record.name = name
          record.code = code
          record.metadata = metadata
          record.lifecycle_status = lifecycle_status
          record.workflow_status = workflow_status
        end
      end
    end

    after(:create) do |page, evaluator|
      next unless evaluator.branch

      BranchPageAppointment.find_or_create_by!(
        company: page.company,
        branch: evaluator.branch,
        page: page
      )
    end
  end
end
