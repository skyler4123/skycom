class ArticleGroupAppointment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :article_group
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true
  belongs_to :appoint_for, polymorphic: true
  belongs_to :appoint_by, polymorphic: true
end
