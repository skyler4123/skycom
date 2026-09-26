module CalendarAdapters
  class BaseAdapter
    attr_reader :integration

    def initialize(calendar_integration)
      @integration = calendar_integration
    end

    def create_event(_calendar_event)
      raise NotImplementedError, "#{self.class} must implement #create_event"
    end

    def update_event(_calendar_event, _sync_mapping)
      raise NotImplementedError, "#{self.class} must implement #update_event"
    end

    def cancel_event(_sync_mapping, reason: nil)
      raise NotImplementedError, "#{self.class} must implement #cancel_event"
    end

    def process_webhook(_payload)
      raise NotImplementedError, "#{self.class} must implement #process_webhook"
    end
  end
end
