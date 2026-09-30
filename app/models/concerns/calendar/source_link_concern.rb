# app/models/concerns/calendar/source_link_concern.rb

# Bridges a calendar_* record to a core ERP model without the calendar module
# ever depending on that model.
#
# Each typed calendar table declares the small set of ERP models it may point
# at, e.g. CalendarPractitioner bridges to Employee or User, CalendarEquipment
# bridges to Stock or Product. Because the link is a polymorphic
# source_type / source_id pair there is no database foreign key, so every write
# path goes through the presence validation declared below.
#
# This is deliberately the ONLY way into the core ERP from the calendar island.
# See docs/CALENDAR.md §2.
module Calendar::SourceLinkConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :source, polymorphic: true, optional: true
  end

  class_methods do
    # Declares the ERP models this calendar table is allowed to point at, e.g.
    #   source_links_to Employee, User
    def source_links_to(*model_names)
      const_set(:SOURCE_TYPES, model_names.map(&:to_s).freeze)
    end

    # Declares that a source link is mandatory (vs. optional). Optional owners
    # (locations, equipment, participants) may exist as calendar-only records.
    #
    # Deliberately NOT `validates :source, presence: true` — ActiveModel runs
    # every validator even after one fails, so that presence check would read
    # the polymorphic association and `constantize` whatever `source_type`
    # holds, turning a typo'd source_type into a NameError instead of a
    # validation error. #source_link_present reads it only once the type is known
    # to be allowed.
    def requires_source_link(required = false)
      # Resolved off the instance so the constant is looked up on the including
      # class, not lexically inside this concern.
      validates :source_type, inclusion: { in: ->(record) { record.class::SOURCE_TYPES } },
        allow_blank: true
      validate :source_link_present, if: -> { required }
    end
  end

  # True only when source_type names a model this table is allowed to bridge to.
  # Guards every polymorphic read so a bad source_type degrades to a validation
  # error rather than a NameError.
  def source_resolvable?
    return false unless linked?
    return false unless self.class::SOURCE_TYPES.include?(source_type)

    source.present?
  end

  # Human label for the linked ERP record, falling back to the calendar record's
  # own `name`. Used by the JSON serializers so the FE never has to resolve the
  # polymorphic record itself.
  def source_display_name
    return name unless source_resolvable?
    return source.try(:name).presence || source.to_s if source.respond_to?(:name)

    source.to_s
  end

  def linked?
    source_type.present? && source_id.present?
  end

  private

  def source_link_present
    return if source_resolvable?

    errors.add(:source, "must reference an existing #{self.class::SOURCE_TYPES.join(' or ')}")
  end
end
