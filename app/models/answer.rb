class Answer < ApplicationRecord
  include TagConcern

  belongs_to :question
end
