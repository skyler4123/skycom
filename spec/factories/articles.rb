# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    association :company
    association :article_group

    initialize_with do
      Seed::ArticleService.create(company: company, article_group: article_group)
    end

    skip_create
  end
end
