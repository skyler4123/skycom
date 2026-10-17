# frozen_string_literal: true

# app/services/storage/statistics_service.rb
#
# Company-wide storage overview for the Storage Statistics page: totals plus
# count/size per coarse file category. Reads StoredFile's audit columns
# (file_size, content_type) only — never Active Storage blobs.
module Storage
  class StatisticsService
    def self.call(company:)
      new(company).call
    end

    def initialize(company)
      @company = company
    end

    def call
      counts = @company.stored_files.group(:content_type).count
      sizes = @company.stored_files.group(:content_type).sum(:file_size)

      by_type = STORED_FILE_MAX_SIZES_BY_TYPE.keys.map do |category|
        content_types = counts.keys.select { |ct| StoredFile.file_category(ct) == category }
        {
          type: category.to_s,
          count: content_types.sum { |ct| counts[ct] },
          size: content_types.sum { |ct| sizes[ct].to_i }
        }
      end

      {
        total_size: by_type.sum { |bucket| bucket[:size] },
        total_files: counts.values.sum,
        total_folders: @company.folders.count,
        by_type: by_type
      }
    end
  end
end
