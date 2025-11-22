module ApplicationRecord::Uuid7Concern
  extend ActiveSupport::Concern

  included do
    before_create :generate_uuid_v7

    private

    def generate_uuid_v7
      return if self.class.attribute_types['id'].type != :uuid
      self.id ||= SecureRandom.uuid_v7
    end
  end
end
