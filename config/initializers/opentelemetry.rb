# config/initializers/opentelemetry.rb

return if Rails.env.test?

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rails"
require "opentelemetry-logs-sdk"
require "opentelemetry/exporter/otlp_logs"
require "opentelemetry/instrumentation/logger"

# 1. FIX: Set explicit, signal-specific OTLP endpoints for OpenObserve
# This stops the SDK from dropping your organization name ("default") from the path.
ENV["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] ||= "http://localhost:5080/api/default/v1/traces"
ENV["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"]   ||= "http://localhost:5080/api/default/v1/logs"

ENV["OTEL_EXPORTER_OTLP_HEADERS"]         ||= "Authorization=Basic YWRtaW5AZXhhbXBsZS5jb206UGFzc3dvcmRAMTIz,organization=default"

# 2. Configure Traces & general instrumentation
OpenTelemetry::SDK.configure do |c|
  c.service_name = "skyceer-#{Rails.env}"

  c.use_all(
    "OpenTelemetry::Instrumentation::Net::HTTP" => {
      untraced_hosts: [ "localhost" ]
    },
    "OpenTelemetry::Instrumentation::ActiveRecord" => { enabled: false },
    "OpenTelemetry::Instrumentation::Rake"         => { enabled: false },
    "OpenTelemetry::Instrumentation::PG"           => { enabled: false },
    "OpenTelemetry::Instrumentation::ActionView"   => { enabled: false },
    "OpenTelemetry::Instrumentation::ActiveStorage"=> { enabled: false },
    "OpenTelemetry::Instrumentation::ConcurrentRuby" => { enabled: false },
    "OpenTelemetry::Instrumentation::Faraday"      => { enabled: false },
    "OpenTelemetry::Instrumentation::Mongo"        => { enabled: false },
    "OpenTelemetry::Instrumentation::Rails"        => { enabled: false },
    "OpenTelemetry::Instrumentation::Redis"        => { enabled: false },
  )
end

# 3. Configure the Logs SDK using the proper SDK namespaces
logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new
processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
  OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
)
logger_provider.add_log_record_processor(processor)

# Set the global logger provider for the application
OpenTelemetry.logger_provider = logger_provider
