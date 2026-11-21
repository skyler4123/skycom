# frozen_string_literal: true

# StoreManager::ConsoleService — one read payload for the Store Manager console.
#
# Every number comes from persisted records. The service delegates the shared
# formulas to SalesSummaryService (invoice totals/tenders), QueueQueryService
# (whole-day handover queue), ShelfQueryService (reorder points/documents) and
# DutyRosterService (real attendance), so the cards, the lists and the close
# sheet cannot disagree.
#
# Docs: docs/business_analysis/06-store-manager.md, docs/OPERATIONS.md
class StoreManager::ConsoleService
  CANCELLED_STATUSES = %w[cancelled refunded].freeze

  def self.call(company:, appointment:, now: Time.current, date: nil, tab: "all", q: nil, page: 1)
    new(
      company: company, appointment: appointment, now: now,
      date: date, tab: tab, q: q, page: page
    ).call
  end

  def initialize(company:, appointment:, now:, date:, tab:, q:, page:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
    @date = (date.presence || LocalTime.today(@branch, at: now)).to_date
    @tab = tab.presence || "all"
    @query = q
    @page = page
  end

  def call
    {
      company: { id: company.id, name: company.name },
      branch: branch_payload,
      currency: company.currency || "usd",
      date: date.iso8601,
      today: today?,
      read_only: !today?,
      now: now.iso8601,
      generated_at: now.iso8601,
      shift: roster[:shift],
      kpis: kpis,
      queue: queue,
      shelf: shelf,
      cashiers: sales[:cashiers],
      unassigned_orders_count: sales[:unassigned_orders_count],
      hourly: hourly,
      staff: roster[:staff],
      footfall: footfall,
      shift_close: StoreManager::ShiftCloseService.show(
        company: company, branch: branch, date: date, now: now
      ),
      reference: reference
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now, :date, :tab, :query, :page

  def today?
    @today ||= LocalTime.today(branch, at: now) == date
  end

  def day_range
    @day_range ||= LocalTime.day_range(date, branch)
  end

  def branch_payload
    {
      id: branch.id,
      name: branch.name,
      code: branch.code,
      phone_number: branch.phone_number
    }
  end

  def saved_close
    @saved_close ||= ShiftClose.find_by(branch_id: branch.id, business_date: date)
  end

  def sales
    @sales ||= StoreManager::SalesSummaryService.call(company: company, branch: branch, date: date)
  end

  def previous_sales
    @previous_sales ||= StoreManager::SalesSummaryService.call(
      company: company, branch: branch, date: date - 1.day
    )
  end

  def queue
    @queue ||= StoreManager::QueueQueryService.call(
      company: company, branch: branch, date: date, now: now,
      tab: tab, q: query, page: page, read_only: !today?
    )
  end

  def shelf
    @shelf ||= StoreManager::ShelfQueryService.call(
      company: company, branch: branch, date: date, now: now, shift_close: saved_close
    )
  end

  def roster
    @roster ||= StoreManager::DutyRosterService.call(
      company: company, branch: branch, date: date, now: now
    )
  end

  def kpis
    {
      gross_sales_cents: sales[:gross_sales_cents],
      previous_gross_sales_cents: previous_sales[:gross_sales_cents],
      gross_sales_delta_pct: percentage_change(sales[:gross_sales_cents], previous_sales[:gross_sales_cents]),
      cashiers_count: sales[:cashiers].length,
      paid_orders_count: sales[:orders_count],
      orders_to_hand_over: queue[:day_counts][:all],
      click_collect_count: queue[:day_counts][:click_collect],
      local_delivery_count: queue[:day_counts][:local_delivery],
      phone_hold_count: queue[:day_counts][:phone_hold],
      shelf_alerts: shelf[:count],
      staff_on_duty: roster[:staff].length
    }
  end

  def hourly
    @hourly ||= begin
      orders = company.orders
        .where(branch_id: branch.id, created_at: day_range, discarded_at: nil)
        .where.not(workflow_status: Order.workflow_statuses.values_at(*CANCELLED_STATUSES))
        .pluck(:created_at)

      counts = orders.each_with_object(Hash.new(0)) do |created_at, buckets|
        buckets[LocalTime.now(branch, at: created_at).hour] += 1
      end
      hours = counts.keys.sort
      buckets = hours.map do |hour|
        { hour: hour, label: format("%02dh", hour), orders_count: counts[hour] }
      end
      peak = buckets.max_by { |bucket| bucket[:orders_count] }
      {
        buckets: buckets,
        peak: peak && peak[:orders_count].positive? ? peak : nil,
        current_hour: today? ? LocalTime.now(branch, at: now).hour : nil
      }
    end
  end

  def footfall
    buyers = company.orders
      .where(branch_id: branch.id, created_at: day_range, discarded_at: nil)
      .where(workflow_status: Order.workflow_statuses.values_at("paid", "completed"))
      .where.not(customer_id: nil)
      .distinct
      .count(:customer_id)

    {
      connected: false,
      buyers: buyers,
      note: "No door sensor"
    }
  end

  def reference
    {
      suppliers: company.suppliers.where(discarded_at: nil).order(:name).map do |supplier|
        { id: supplier.id, name: supplier.name }
      end
    }
  end

  def percentage_change(current, previous)
    return nil if previous.to_d.zero?

    (((current.to_d - previous.to_d) / previous.to_d) * 100).round(1)
  end
end
