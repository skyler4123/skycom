class Article < ApplicationRecord
  belongs_to :article_group
  belongs_to :company_group
  belongs_to :company
end
