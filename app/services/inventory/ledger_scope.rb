# frozen_string_literal: true

# Inventory::LedgerScope — the one query object behind the Inventory ledger:
# warehouse scope, text search, availability bucket, tab counts, the row cap,
# and the uncapped export rows.
#
# Why it exists: the console payload, the CSV export, and the tab counts must
# agree on what is in the ledger. Keeping the scope in one place means a row
# shown on screen and a row written to the file can never disagree.
# How it works: base_scope is the warehouse (or branch) stock relation with
# discarded rows removed; search narrows it through Meilisearch ids (name, code,
# location only, filtered by company + warehouse); the bucket scopes come from
# Stock so "out/low/in_stock" have one definition. Counts are warehouse totals
# for the current search, never the capped page.
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/MEILISEARCH.md
class Inventory::LedgerScope
  BUCKETS = %w[all low out in_stock].freeze
  LEDGER_LIMIT = 200
  # Meilisearch caps a single search at 1,000 hits — the ledger's own cap is far
  # lower, so this bounds the id list without hiding a reachable row today.
  SEARCH_LIMIT = 1_000
  SEARCH_ATTRIBUTES = %w[name code property_string_1].freeze

  def initialize(company:, appointment:, q: nil, bucket: "all", limit: LEDGER_LIMIT)
    @company = company
    @appointment = appointment
    @warehouse = appointment.respond_to?(:warehouse) ? appointment.warehouse : nil
    @branch = @warehouse&.branch || (appointment.respond_to?(:branch) ? appointment.branch : nil)
    @query = q.to_s.strip
    @bucket = BUCKETS.include?(bucket.to_s) ? bucket.to_s : "all"
    @limit = limit
  end

  attr_reader :company, :warehouse, :branch, :limit, :bucket, :query

  # Warehouse/branch + not discarded. No search, no bucket — KPI totals use this.
  def base_scope
    @base_scope ||= begin
      scope = company.stocks.where(discarded_at: nil)
      if warehouse.present?
        scope.where(warehouse_id: warehouse.id)
      elsif branch.present?
        scope.where(branch_id: branch.id)
      else
        scope.none
      end
    end
  end

  def rows
    @rows ||= ordered_scope.limit(limit).map { present(_1) }
  end

  def export_rows
    ordered_scope.limit(EXPORT_MAX_RECORDS).map { present(_1) }
  end

  def total
    @total ||= view_scope.count
  end

  def counts
    @counts ||= BUCKETS.index_with { |key| view_scope(bucket: key).count }
  end

  def capped?
    total > limit
  end

  def search_active?
    query.present?
  end

  def warehouse_code
    (warehouse&.code.presence || "warehouse").parameterize
  end

  private

  def present(stock)
    Stocks::RowPresenter.call(stock, company: company)
  end

  def ordered_scope
    view_scope.includes(:product).order(:name, :id)
  end

  def view_scope(bucket: self.bucket)
    scope = apply_bucket(base_scope, bucket)
    ids = search_ids
    ids.nil? ? scope : scope.where(id: ids)
  end

  def apply_bucket(scope, key)
    case key
    when "low" then scope.low_stock
    when "out" then scope.out_of_stock
    when "in_stock" then scope.in_stock
    else scope
    end
  end

  def search_ids
    return @search_ids if defined?(@search_ids)

    @search_ids = if query.blank?
      nil
    else
      Stock.ms_raw_search(
        query,
        filter: filter_string,
        hits_per_page: SEARCH_LIMIT,
        matching_strategy: "all",
        attributes_to_search_on: SEARCH_ATTRIBUTES
      ).fetch("hits", []).map { _1["id"] }
    end
  end

  def filter_string
    parts = [ %(company_id = "#{company.id}") ]
    if warehouse.present?
      parts << %(warehouse_id = "#{warehouse.id}")
    elsif branch.present?
      parts << %(branch_id = "#{branch.id}")
    end
    parts.join(" AND ")
  end
end
