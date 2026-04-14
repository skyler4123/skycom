# spec/factories/article_groups.rb
FactoryBot.define do
  factory :article_group do
    association :company

    initialize_with do
      Seed::ArticleGroupService.create(company: company)
    end

    skip_create
  end
end
