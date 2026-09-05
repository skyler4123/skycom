# frozen_string_literal: true

module StandardPropertiesConcern
  extend ActiveSupport::Concern

  # Default DB columns published as "defined properties" — BE-controlled labels
  # that flow through PropertyMapping + TableConfig like dynamic properties.
  # Models override this constant to change/limit the set (e.g. drop `code`).
  STANDARD_PROPERTIES = {
    "name"            => "Name",
    "description"     => "Description",
    "code"            => "Code",
    "workflow_status" => "Workflow Status"
  }.freeze

  class_methods do
    # Full entry hashes consumable by PropertyMapping.defined_property_entries.
    def standard_property_entries
      standard_properties.map do |key, label|
        {
          "key"       => key,
          "name"      => label,
          "type"      => "string",
          "validates" => {},
          "defined"   => true
        }
      end
    end

    def standard_property_keys
      standard_properties.keys
    end

    def standard_properties
      STANDARD_PROPERTIES
    end
  end
end
