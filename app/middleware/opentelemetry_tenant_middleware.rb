# app/middleware/opentelemetry_tenant_middleware.rb
class OpentelemetryTenantMiddleware
  COMPANIES_PATH_REGEX = %r{\A/companies/([^/?]+)}

  def initialize(app)
    @app = app
  end

  def call(env)
    if (match = env["PATH_INFO"]&.match(COMPANIES_PATH_REGEX))
      company_id = match[1]
    else
      company_id = "public"
    end

    current_span = OpenTelemetry::Trace.current_span
    # If this evaluates to false, it means OpenTelemetry Rack instrumentation is completely turned off
    if current_span.recording?
      current_span.set_attribute('company_id', company_id)
    else
      # Fallback log warning to your local Rails console if the span isn't tracking yet
      Rails.logger.warn "OpenTelemetry: No active recording span found for path #{env['PATH_INFO']}"
    end

    @app.call(env)
  end
end
