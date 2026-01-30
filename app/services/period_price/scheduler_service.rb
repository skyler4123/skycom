class PeriodPrice::SchedulerService
  def initialize(period_priceable)
    @period_priceable = period_priceable # This is the 'appoint_to' polymorphic record
  end

  # Defaults to nil (Infinity) if arguments are missing
  def schedule(amount:, start_at: nil, end_at: nil, currency_code: 0, timezone: 0)
    PeriodPriceAppointment.transaction do
      target_price = find_or_create_price(amount, currency)

      # CASE 1: The "Global Reset" (Infinite Start AND Infinite End)
      # User wants this price to be the ONLY price forever.
      if start_at.nil? && end_at.nil?
        reset_to_forever_price(target_price, timezone)
      
      # CASE 2: Standard Range (or partial infinity)
      else
        # We need "Safe Dates" for comparison logic, but we save 'nil' to DB
        # If start_at is nil, treat as VERY OLD date. If end_at is nil, treat as FAR FUTURE.
        safe_start = start_at || DateTime.new(0) 
        safe_end   = end_at   || DateTime::Infinity.new

        handle_overlaps(safe_start, safe_end)
        create_appointment(target_price, start_at, end_at, timezone)
      end
    end
  end

  private

  def reset_to_forever_price(price_record, timezone)
    # 1. Clear ALL existing price appointments for this product
    PeriodPriceAppointment.where(appoint_to: @product).destroy_all

    # 2. Create one single "Forever" record
    period_record = find_or_create_period(nil, nil, timezone) # nil, nil = Forever

    PeriodPriceAppointment.create!(
      appoint_to: @product,
      price: price_record,
      period: period_record
    )
  end

  def handle_overlaps(new_start, new_end)
    # Query for Overlaps handling NULLs correctly
    # Logic: (StartA < EndB) AND (EndA > StartB)
    # In SQL, NULL usually acts as "Infinity" for logic if we handle it explicitly.
    
    overlaps = PeriodPriceAppointment.joins(:period).where(appoint_to: @product)

    # We filter in Ruby or strict SQL depending on DB. 
    # For safety with NULLs, specific SQL is required:
    overlaps = overlaps.where("
      (periods.start_at IS NULL OR periods.start_at < ?) 
      AND 
      (periods.end_at IS NULL OR periods.end_at > ?)
    ", new_end, new_start)

    overlaps.each do |appt|
      # ... (Logic from previous answer to split head/tail) ...
      # Be careful: existing period.start_at might be nil!
      
      p_start = appt.period.start_at || DateTime.new(0) # Handle -Infinity
      p_end   = appt.period.end_at   || DateTime::Infinity.new # Handle +Infinity
      
      # 1. Create Head (Only if the old start is before the new start)
      if p_start < new_start
        create_appointment(appt.price, appt.period.start_at, new_start, appt.period.timezone)
      end

      # 2. Create Tail (Only if the old end is after the new end)
      if p_end > new_end
        create_appointment(appt.price, new_end, appt.period.end_at, appt.period.timezone)
      end

      # 3. Destroy original
      appt.destroy!
    end
  end

  # Update helper to allow nils
  def create_appointment(price_record, start_time, end_time, tz)
    # Guard clause: If dates are provided but Start > End, do nothing
    return if start_time && end_time && start_time >= end_time

    period_record = find_or_create_period(start_time, end_time, tz)
    
    PeriodPriceAppointment.create!(
      appoint_to: @product,
      price: price_record,
      period: period_record
    )
  end

  # Database Optimization: Reuse existing Prices
  def find_or_create_price(amount, currency)
    Seed::PriceService.create(amount: amount, currency_code: currency)
  end

  # Database Optimization: Reuse existing Periods
  def find_or_create_period(start_at, end_at, timezone)
    Period.find_or_create_by!(
      start_at: start_at, 
      end_at: end_at, 
      timezone: timezone
    )
  end
end
