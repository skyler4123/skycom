class EmailService
  attr_reader :username, :full_domain, :domain, :top_level_domain

  def initialize(email)
    @email = email.to_s.strip.downcase
    parse_email
  end

  private

  def parse_email
    return unless @email.include?("@")

    # Destructuring the split array
    @username, @full_domain = @email.split("@")

    if @full_domain
      domain_parts = @full_domain.split(".")
      @domain = domain_parts.first
      @top_level_domain = domain_parts.last
    end
  end
end
