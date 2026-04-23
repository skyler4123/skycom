# spec/factories/article_groups.rb
FactoryBot.define do
  factory :article_group do
    association :company

    initialize_with do
      Seed::ArticleGroupService.new(company: company)
    end

  end
end
