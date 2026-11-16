# config/initializers/opentelemetry.rb

return if Rails.env.test?

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/rails"
require "opentelemetry-logs-sdk"
require "opentelemetry/exporter/otlp_logs"
require "opentelemetry/instrumentation/logger"

# 1. The OTel SDK reads OTEL_* from ENV itself, so publish the resolved
# constants (ENV > credentials > default) into ENV. This file is the documented
# bridge; see docs/ENVIRONMENT.md.
ENV["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] = OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
ENV["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"]   = OTEL_EXPORTER_OTLP_LOGS_ENDPOINT
ENV["OTEL_EXPORTER_OTLP_HEADERS"]         = OTEL_EXPORTER_OTLP_HEADERS

# 2. Configure Traces & general instrumentation
OpenTelemetry::SDK.configure do |c|
  c.service_name = OTEL_SERVICE_NAME

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
