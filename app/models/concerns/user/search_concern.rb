module User::SearchConcern
  extend ActiveSupport::Concern

  included do
    include Meilisearch::Rails

    meilisearch do
      attribute :email, :username, :name, :first_name, :last_name, :phone_number # only the attributes 'title', and 'author' will be sent to Meilisearch
      # all attributes will be sent to Meilisearch if block is left empty
      
      searchable_attributes [:email, :username, :name, :first_name, :last_name, :phone_number] # only the attributes 'title', and 'author' will be sent to Meilisearch
    end
  end
end

# Example:

# meilisearch do
#   searchable_attributes [:title, :author, :publisher, :description]
#   filterable_attributes [:genre]
#   sortable_attributes [:title]
#   ranking_rules [
#     'proximity',
#     'typo',
#     'words',
#     'attribute',
#     'sort',
#     'exactness',
#     'publication_year:desc'
#   ]
#   synonyms nyc: ['new york']

#   # The following parameters are applied when calling the search() method:
#   attributes_to_highlight ['*']
#   attributes_to_crop [:description]
#   crop_length 10
#   faceting max_values_per_facet: 2000
#   pagination max_total_hits: 1000
#   proximity_precision 'byWord'
# end