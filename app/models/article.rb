class Article < ApplicationRecord
  include TagConcern

  belongs_to :article_group
  belongs_to :company
  belongs_to :branch, optional: true
end
