# frozen_string_literal: true

# Opens a migration session: the shared "Migrations" root folder, a
# migration-only child folder that holds its chunks, and the draft record
# linking both.
module CompanyMigrations
  class SetupService
    ROOT_FOLDER_NAME = "Migrations"

    def self.call(company:, name:, source_filename: nil, source_file_size: nil)
      new(
        company: company,
        name: name,
        source_filename: source_filename,
        source_file_size: source_file_size
      ).call
    end

    def initialize(company:, name:, source_filename:, source_file_size:)
      @company = company
      @name = name
      @source_filename = source_filename
      @source_file_size = source_file_size
    end

    def call
      root = @company.folders.find_or_create_by!(parent_id: nil, name: ROOT_FOLDER_NAME)
      folder = root.children.create!(company: @company, name: @name.presence || "Migration #{SecureRandom.hex(4)}")

      @company.company_migrations.create!(
        name: @name,
        folder: folder,
        source_filename: @source_filename,
        source_file_size: @source_file_size,
        workflow_status: :draft
      )
    end
  end
end
