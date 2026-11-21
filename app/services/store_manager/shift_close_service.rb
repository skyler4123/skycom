# frozen_string_literal: true

# StoreManager::ShiftCloseService — builds and stores the close-of-shift sheet.
#
# The sheet is computed from records, but once saved every report figure is
# stored on ShiftClose: a later sale must not rewrite a closed day. Re-saving
# today's close recalculates the figures and updates the same row.
#
# Docs: docs/business_analysis/06-store-manager.md, docs/MONEY_FLOW.md
class StoreManager::ShiftCloseService
  def self.show(company:, branch:, date:, now: Time.current)
    new(company: company, branch: branch, date: date, now: now).show
  end

  def self.save(company:, branch:, employee:, date:, opening_float_cents:, counted_cash_cents:, note:, now: Time.current)
    new(company: company, branch: branch, date: date, now: now).save(
      employee: employee,
      opening_float_cents: opening_float_cents,
      counted_cash_cents: counted_cash_cents,
      note: note
    )
  end

  def initialize(company:, branch:, date:, now:)
    @company = company
    @branch = branch
    @date = date.to_date
    @now = now
  end

  def show
    return saved_payload if saved_close.present?
    return nil unless today?

    live_payload
  end

  def save(employee:, opening_float_cents:, counted_cash_cents:, note:)
    raise StoreManager::Error, "Only today's shift can be closed." unless today?

    opening_float = normalize_money!(opening_float_cents, "Enter the opening float.")
    counted = normalize_money!(counted_cash_cents, "Enter the counted cash.")
    summary = sales_summary
    shelf = shelf_payload
    roster = roster_payload
    expected = opening_float + summary[:cash_received_cents].to_i - summary[:change_cents].to_i
    variance = counted - expected
    close = nil

    branch.with_lock do
      existing = ShiftClose.find_by(branch_id: branch.id, business_date: date)
      close = existing || ShiftClose.new(company: company, branch: branch, business_date: date)
      close.assign_attributes(
        closed_by: employee,
        closed_by_name: employee&.name,
        shift_name: roster.dig(:shift, :name),
        shift_started_at: parse_time(roster.dig(:shift, :starts_at)),
        shift_ended_at: parse_time(roster.dig(:shift, :ends_at)),
        gross_sales_cents: summary[:gross_sales_cents],
        cash_sales_cents: summary[:cash_sales_cents],
        qr_sales_cents: summary[:qr_sales_cents],
        other_sales_cents: summary[:other_sales_cents],
        cash_received_cents: summary[:cash_received_cents],
        change_cents: summary[:change_cents],
        orders_count: summary[:orders_count],
        discounts_cents: summary[:discounts_cents],
        tax_cents: summary[:tax_cents],
        opening_float_cents: opening_float,
        expected_cash_cents: expected,
        counted_cash_cents: counted,
        variance_cents: variance,
        open_handovers_snapshot: open_handovers_snapshot,
        open_handovers_count: open_handovers_snapshot.length,
        shelf_short_count: shelf[:count],
        staff_names: roster[:staff].map { |row| row[:name] },
        shelf_snapshot: shelf[:rows].map { |row| row.deep_stringify_keys },
        tender_lines: summary[:tender_lines],
        note: note.presence,
        closed_at: now
      )
      close.save!
    end

    {
      message: "Shift close saved for #{date.strftime('%b %-d, %Y')}.",
      shift_close: saved_payload(close)
    }
  end

  private

  attr_reader :company, :branch, :date, :now

  def today?
    @today ||= LocalTime.today(branch, at: now) == date
  end

  def saved_close
    @saved_close ||= ShiftClose.find_by(branch_id: branch.id, business_date: date)
  end

  def sales_summary
    @sales_summary ||= StoreManager::SalesSummaryService.call(company: company, branch: branch, date: date)
  end

  def shelf_payload
    @shelf_payload ||= StoreManager::ShelfQueryService.call(
      company: company, branch: branch, date: date, now: now
    )
  end

  def roster_payload
    @roster_payload ||= StoreManager::DutyRosterService.call(
      company: company, branch: branch, date: date, now: now
    )
  end

  def open_handovers_snapshot
    @open_handovers_snapshot ||= StoreManager::QueueQueryService.open_handovers(
      company: company, branch: branch, date: date, now: now
    )
  end

  def live_payload
    expected = sales_summary[:cash_received_cents].to_i - sales_summary[:change_cents].to_i
    {
      date: date.iso8601,
      today: true,
      read_only: false,
      saved: false,
      closed_at: nil,
      closed_by_name: nil,
      shift: roster_payload[:shift],
      sales: sales_payload(sales_summary),
      opening_float_cents: 0,
      expected_cash_cents: expected,
      counted_cash_cents: nil,
      variance_cents: nil,
      open_handovers: open_handovers_snapshot,
      open_handovers_count: open_handovers_snapshot.length,
      shelf_short_count: shelf_payload[:count],
      staff: roster_payload[:staff],
      note: nil
    }
  end

  def saved_payload(close = saved_close)
    {
      date: close.business_date.iso8601,
      today: today?,
      read_only: !today?,
      saved: true,
      closed_at: LocalTime.utc_iso(close.closed_at),
      closed_by_name: close.closed_by_name,
      shift: {
        name: close.shift_name,
        starts_at: LocalTime.utc_iso(close.shift_started_at),
        ends_at: LocalTime.utc_iso(close.shift_ended_at),
        checked_in_count: Array(close.staff_names).length,
        shift_count: 1
      },
      sales: {
        gross_sales_cents: close.gross_sales_cents.to_i,
        orders_count: close.orders_count.to_i,
        discounts_cents: close.discounts_cents.to_i,
        tax_cents: close.tax_cents.to_i,
        cash_sales_cents: close.cash_sales_cents.to_i,
        qr_sales_cents: close.qr_sales_cents.to_i,
        other_sales_cents: close.other_sales_cents.to_i,
        cash_received_cents: close.cash_received_cents.to_i,
        change_cents: close.change_cents.to_i,
        tender_lines: close.tender_lines
      },
      opening_float_cents: close.opening_float_cents.to_i,
      expected_cash_cents: close.expected_cash_cents.to_i,
      counted_cash_cents: close.counted_cash_cents.to_i,
      variance_cents: close.variance_cents.to_i,
      open_handovers: Array(close.open_handovers_snapshot).map { |row| row.deep_symbolize_keys },
      open_handovers_count: close.open_handovers_count.to_i,
      shelf_short_count: close.shelf_short_count.to_i,
      staff: Array(close.staff_names).map { |name| { name: name } },
      shelf_rows: Array(close.shelf_snapshot).map { |row| row.deep_symbolize_keys.merge(read_only: true) },
      note: close.note
    }
  end

  def sales_payload(summary)
    {
      gross_sales_cents: summary[:gross_sales_cents],
      orders_count: summary[:orders_count],
      discounts_cents: summary[:discounts_cents],
      tax_cents: summary[:tax_cents],
      cash_sales_cents: summary[:cash_sales_cents],
      qr_sales_cents: summary[:qr_sales_cents],
      other_sales_cents: summary[:other_sales_cents],
      cash_received_cents: summary[:cash_received_cents],
      change_cents: summary[:change_cents],
      tender_lines: summary[:tender_lines]
    }
  end

  def normalize_money!(value, message)
    number = Integer(value, exception: false)
    raise StoreManager::Error, message if number.nil? || number.negative?

    number
  end

  def parse_time(value)
    return nil if value.blank?

    Time.iso8601(value)
  rescue ArgumentError
    nil
  end
end
