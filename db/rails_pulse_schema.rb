# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 0) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "rails_pulse_deployments", force: :cascade do |t|
    t.string "revision", null: false, comment: "Git SHA, tag, or version string"
    t.datetime "started_at", null: false, comment: "When the deployment started"
    t.datetime "finished_at", comment: "When the deployment finished (nil if still in progress or unknown)"
    t.text "metadata", comment: "JSON object of arbitrary deployment metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "revision" ], name: "index_rails_pulse_deployments_on_revision"
    t.index [ "started_at" ], name: "index_rails_pulse_deployments_on_started_at"
  end

  create_table "rails_pulse_job_runs", force: :cascade do |t|
    t.bigint "job_id", null: false, comment: "Link to job definition"
    t.string "run_id", null: false, comment: "Adapter specific run id"
    t.decimal "duration", precision: 15, scale: 6, comment: "Execution duration in milliseconds"
    t.string "status", null: false, comment: "Execution status"
    t.string "error_class", comment: "Error class name"
    t.text "error_message", comment: "Error message"
    t.integer "attempts", default: 0, null: false, comment: "Retry attempts"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the job started"
    t.datetime "enqueued_at", precision: nil, comment: "When the job was enqueued"
    t.text "arguments", comment: "Serialized arguments"
    t.string "adapter", comment: "Queue adapter"
    t.text "tags", comment: "Execution tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "job_id", "occurred_at" ], name: "index_rails_pulse_job_runs_on_job_and_occurred"
    t.index [ "job_id", "status" ], name: "index_rails_pulse_job_runs_on_job_and_status"
    t.index [ "job_id" ], name: "index_rails_pulse_job_runs_on_job_id"
    t.index [ "occurred_at" ], name: "index_rails_pulse_job_runs_on_occurred_at"
    t.index [ "run_id" ], name: "index_rails_pulse_job_runs_on_run_id", unique: true
    t.index [ "status" ], name: "index_rails_pulse_job_runs_on_status"
  end

  create_table "rails_pulse_jobs", force: :cascade do |t|
    t.string "name", null: false, comment: "Job class name"
    t.string "queue_name", comment: "Default queue"
    t.text "description", comment: "Optional description"
    t.integer "runs_count", default: 0, null: false, comment: "Cache of total runs"
    t.integer "failures_count", default: 0, null: false, comment: "Cache of failed runs"
    t.integer "retries_count", default: 0, null: false, comment: "Cache of retried runs"
    t.decimal "avg_duration", precision: 15, scale: 6, comment: "Average duration in milliseconds"
    t.decimal "p95_duration", precision: 15, scale: 6, comment: "95th percentile duration in milliseconds"
    t.decimal "p99_duration", precision: 15, scale: 6, comment: "99th percentile duration in milliseconds"
    t.text "tags", comment: "JSON array of tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_rails_pulse_jobs_on_name", unique: true
    t.index [ "queue_name" ], name: "index_rails_pulse_jobs_on_queue"
    t.index [ "runs_count" ], name: "index_rails_pulse_jobs_on_runs_count"
  end

  create_table "rails_pulse_operations", force: :cascade do |t|
    t.bigint "request_id", comment: "Link to the request"
    t.bigint "job_run_id", comment: "Link to a background job execution"
    t.bigint "query_id", comment: "Link to the normalized SQL query"
    t.string "operation_type", null: false, comment: "Type of operation (e.g., database, view, gem_call)"
    t.string "label", null: false, comment: "Display label: normalized SQL (≤255) for sql ops, controller#action / render path / cache key etc. for others"
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Operation duration in milliseconds"
    t.string "codebase_location", comment: "File and line number (e.g., app/models/user.rb:25)"
    t.float "start_time", default: 0.0, null: false, comment: "Operation start time in milliseconds"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.integer "row_count", comment: "Number of rows returned (SQL operations, Rails 7.1+)"
    t.boolean "cache_hit", comment: "Whether a cache_read operation hit the cache"
    t.text "actual_sql", comment: "Actual SQL that ran for sql operations — comment-stripped, unparameterized, unbounded"
    t.text "repeated_query_group", comment: "Normalized SQL key identifying an N+1 group"
    t.integer "repetition_count", comment: "Number of times this query pattern repeated in the request"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "created_at", "query_id" ], name: "idx_operations_for_aggregation"
    t.index [ "job_run_id" ], name: "index_rails_pulse_operations_on_job_run_id"
    t.index [ "occurred_at", "duration", "operation_type" ], name: "index_rails_pulse_operations_on_time_duration_type"
    t.index [ "operation_type" ], name: "index_rails_pulse_operations_on_operation_type"
    t.index [ "query_id", "duration", "occurred_at" ], name: "index_rails_pulse_operations_query_performance"
    t.index [ "query_id", "occurred_at" ], name: "index_rails_pulse_operations_on_query_and_time"
    t.index [ "request_id" ], name: "index_rails_pulse_operations_on_request_id"
    t.check_constraint "request_id IS NOT NULL OR job_run_id IS NOT NULL", name: "rails_pulse_operations_request_or_job_run"
  end

  create_table "rails_pulse_queries", force: :cascade do |t|
    t.string "hashed_sql", limit: 32, null: false, comment: "MD5 hash of normalized SQL for fast lookups and uniqueness"
    t.text "normalized_sql", null: false, comment: "Full normalized SQL query string (e.g., SELECT * FROM users WHERE id = ?)"
    t.datetime "analyzed_at", comment: "When query analysis was last performed"
    t.text "explain_plan", comment: "EXPLAIN output from actual SQL execution"
    t.text "issues", comment: "JSON array of detected performance issues"
    t.text "metadata", comment: "JSON object containing query complexity metrics"
    t.text "query_stats", comment: "JSON object with query characteristics analysis"
    t.text "backtrace_analysis", comment: "JSON object with call chain and N+1 detection"
    t.text "index_recommendations", comment: "JSON array of database index recommendations"
    t.text "n_plus_one_analysis", comment: "JSON object with enhanced N+1 query detection results"
    t.text "suggestions", comment: "JSON array of optimization recommendations"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "hashed_sql" ], name: "index_rails_pulse_queries_on_hashed_sql", unique: true
  end

  create_table "rails_pulse_requests", force: :cascade do |t|
    t.bigint "route_id", null: false, comment: "Link to the route"
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Total request duration in milliseconds"
    t.integer "status", null: false, comment: "HTTP status code (e.g., 200, 500)"
    t.boolean "is_error", default: false, null: false, comment: "True if status >= 500"
    t.string "request_uuid", null: false, comment: "Unique identifier for the request (e.g., UUID)"
    t.string "controller_action", comment: "Controller and action handling the request (e.g., PostsController#show)"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.integer "response_size_bytes", comment: "HTTP response body size in bytes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "created_at", "route_id" ], name: "idx_requests_for_aggregation"
    t.index [ "occurred_at" ], name: "index_rails_pulse_requests_on_occurred_at"
    t.index [ "request_uuid" ], name: "index_rails_pulse_requests_on_request_uuid", unique: true
    t.index [ "route_id", "occurred_at" ], name: "index_rails_pulse_requests_on_route_id_and_occurred_at"
    t.index [ "route_id" ], name: "index_rails_pulse_requests_on_route_id"
  end

  create_table "rails_pulse_routes", force: :cascade do |t|
    t.string "method", null: false, comment: "HTTP method (e.g., GET, POST)"
    t.string "path", null: false, comment: "Request path (e.g., /posts/index)"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "method", "path" ], name: "index_rails_pulse_routes_on_method_and_path", unique: true
    t.index [ "path" ], name: "index_rails_pulse_routes_on_path"
  end

  create_table "rails_pulse_summaries", force: :cascade do |t|
    t.datetime "period_start", null: false, comment: "Start of the aggregation period"
    t.datetime "period_end", null: false, comment: "End of the aggregation period"
    t.string "period_type", null: false, comment: "Aggregation period type: hour, day, week, month"
    t.string "summarizable_type", null: false
    t.bigint "summarizable_id", null: false, comment: "Link to Route or Query"
    t.integer "count", default: 0, null: false, comment: "Total number of requests/operations"
    t.float "avg_duration", comment: "Average duration in milliseconds"
    t.float "min_duration", comment: "Minimum duration in milliseconds"
    t.float "max_duration", comment: "Maximum duration in milliseconds"
    t.float "p50_duration", comment: "50th percentile duration"
    t.float "p95_duration", comment: "95th percentile duration"
    t.float "p99_duration", comment: "99th percentile duration"
    t.float "total_duration", comment: "Total duration in milliseconds"
    t.float "stddev_duration", comment: "Standard deviation of duration"
    t.integer "error_count", default: 0, comment: "Number of error responses (5xx)"
    t.integer "success_count", default: 0, comment: "Number of successful responses"
    t.integer "status_2xx", default: 0, comment: "Number of 2xx responses"
    t.integer "status_3xx", default: 0, comment: "Number of 3xx responses"
    t.integer "status_4xx", default: 0, comment: "Number of 4xx responses"
    t.integer "status_5xx", default: 0, comment: "Number of 5xx responses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "created_at" ], name: "index_rails_pulse_summaries_on_created_at"
    t.index [ "period_start" ], name: "index_rails_pulse_summaries_on_period_start"
    t.index [ "period_type", "period_start" ], name: "index_rails_pulse_summaries_on_period"
    t.index [ "summarizable_id" ], name: "index_rails_pulse_summaries_on_summarizable_id"
    t.index [ "summarizable_type", "summarizable_id", "period_type", "period_start" ], name: "idx_pulse_summaries_unique", unique: true
    t.index [ "summarizable_type", "summarizable_id" ], name: "index_rails_pulse_summaries_on_summarizable"
  end

  add_foreign_key "rails_pulse_job_runs", "rails_pulse_jobs", column: "job_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_job_runs", column: "job_run_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_queries", column: "query_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_requests", column: "request_id"
  add_foreign_key "rails_pulse_requests", "rails_pulse_routes", column: "route_id"
end
