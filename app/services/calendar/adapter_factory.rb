# app/services/calendar/adapter_factory.rb
#
# Single entry point for "give me the adapter that talks to <provider> for this
# company". Controllers and jobs depend on this, never on a concrete adapter, so
# registering a new provider is a one-line change here.
#
# The registry is intentionally empty in v1: Skycom runs its own scheduling, and
# no provider is connected. `available?` lets the Sync page report that
# honestly instead of raising.
#
# @see docs/CALENDAR.md §7
class Calendar::AdapterFactory
  class UnknownProvider < StandardError; end

  # provider key => adapter class name. Populate as adapters land, e.g.
  #   "calcom" => "Calendar::CalcomAdapter"
  REGISTRY = {}.freeze

  def self.for(company, provider: "calcom")
    raise UnknownProvider, "Unknown calendar provider: #{provider}" unless available?(provider)

    REGISTRY.fetch(provider).constantize.new(company)
  end

  def self.available?(provider)
    REGISTRY.key?(provider.to_s)
  end

  def self.registered_providers
    REGISTRY.keys
  end
end
