# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    association :company
    association :article_group

    initialize_with do
      Seed::ArticleService.new(company: company, article_group: article_group)
    end

  end
end
