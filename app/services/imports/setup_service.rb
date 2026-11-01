# frozen_string_literal: true

# Opens an Import session: the shared "Imports" root folder, a child folder
# that holds the source CSV, and the draft import linking both. The creator is
# the employee who will receive finish/rollback notifications.
module Imports
  class SetupService
    def self.call(company:, creator:, name:, description: nil)
      new(company: company, creator: creator, name: name, description: description).call
    end

    def initialize(company:, creator:, name:, description:)
      @company = company
      @creator = creator
      @name = name
      @description = description
    end

    def call
      Import.transaction do
        root = @company.folders.find_or_create_by!(parent_id: nil, name: IMPORT_ROOT_FOLDER_NAME)
        folder = root.children.create!(
          company: @company,
          name: @name.presence || "Import #{SecureRandom.hex(4)}"
        )

        @company.imports.create!(
          name: @name,
          description: @description,
          creator: @creator,
          folder: folder,
          workflow_status: :draft
        )
      end
    end
  end
end
