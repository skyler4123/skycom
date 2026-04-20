module CompanyFromAssociation
  extend ActiveSupport::Concern

  included do
    before_validation :set_company_from_association
  end

  private

  def set_company_from_association
    self.company_id ||= detect_company_from_primary_association
    self.company_id ||= detect_company_from_appoint_to
  end

  def detect_company_from_primary_association
    reflections = self.class.reflect_on_all_associations(:belongs_to)
    return nil unless reflections.any? { |r| r.name == :company }

    primary_reflection = reflections.find do |r|
      r.name != :company &&
      r.name != :appoint_to &&
      r.name != :appoint_from &&
      r.name != :appoint_for &&
      r.name != :appoint_by &&
      !r.options[:polymorphic]
    end

    return nil unless primary_reflection

    primary_association = send(primary_reflection.name)
    primary_association&.company_id
  end

  def detect_company_from_appoint_to
    return nil unless respond_to?(:appoint_to) && appoint_to

    if appoint_to.respond_to?(:company_id)
      appoint_to.company_id
    elsif appoint_to.respond_to?(:company)
      appoint_to.company&.id
    end
  end
end
