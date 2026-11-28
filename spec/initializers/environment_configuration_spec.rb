# frozen_string_literal: true

require "rails_helper"
require "open3"

# Proves the environment-backed constants declared in
# config/initializers/constants.rb follow the documented precedence:
# ENV > Rails.application.credentials > hardcoded default.
# See docs/ENVIRONMENT.md.
RSpec.describe "Environment-backed constants" do
  CATALOG = %w[
    MEILISEARCH_HOST MEILISEARCH_API_KEY
    CENTRIFUGO_API_KEY CENTRIFUGO_ENDPOINT CENTRIFUGO_TOKEN_HMAC_SECRET_KEY
    GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET
    MOCK_QR_GATEWAY_URL MOCK_QR_WEBHOOK_URL
    MOCK_REDIRECT_GATEWAY_URL MOCK_REDIRECT_WEBHOOK_URL MOCK_API_PING_URL
    WEBHOOK_BANK_PAYMENT_SECRET WEBHOOK_REDIRECT_PAYMENT_SECRET
    JOB_CONCURRENCY
    REDIS_URL_PRODUCTION REDIS_URL_DEVELOPMENT REDIS_URL_TEST
    AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_ENDPOINT_URL
    MISSION_CONTROL_USER MISSION_CONTROL_PASSWORD
    TEST_ENV_NUMBER TEST_RUN_INSIDE_DOCKER SKIP_DB_SEED
  ].freeze

  # Runs the code in a fresh Rails boot so the constant is resolved by the
  # initializer under the given ENV, not by the already-booted test process.
  def constant_from_runner(code, env = {})
    stdout, stderr, status = Open3.capture3(env, "bin/rails", "runner", code, chdir: Rails.root.to_s)
    raise "bin/rails runner failed:\n#{stderr}" unless status.success?

    stdout
  end

  describe "precedence" do
    it "prefers ENV over credentials and the default" do
      expect(
        constant_from_runner("print MEILISEARCH_HOST", "MEILISEARCH_HOST" => "http://env.test")
      ).to eq("http://env.test")
    end

    it "falls back to the default when ENV and credentials are unset" do
      # :mission_control_user is a new credential key, so it is absent from
      # the encrypted file in every environment.
      expect(
        constant_from_runner("print MISSION_CONTROL_USER", "MISSION_CONTROL_USER" => nil)
      ).to eq("dev")
    end
  end

  describe "typed values" do
    it "coerces integer constants" do
      expect(
        constant_from_runner("print JOB_CONCURRENCY.class", "JOB_CONCURRENCY" => "7")
      ).to eq("Integer")
      expect(
        constant_from_runner("print JOB_CONCURRENCY", "JOB_CONCURRENCY" => "7")
      ).to eq("7")
    end

    it "treats the string false as false" do
      expect(
        constant_from_runner("print TEST_RUN_INSIDE_DOCKER", "TEST_RUN_INSIDE_DOCKER" => "false")
      ).to eq("false")
    end
  end

  describe "infrastructure YAML" do
    it "scopes the test Redis URL to the parallel worker" do
      url = Rails.application.config_for("redis/shared")[:url]
      expected_db = (TEST_ENV_NUMBER.presence || 1).to_i

      expect(url).to eq("redis://127.0.0.1:6379/#{expected_db}")
    end
  end

  it "declares every catalog constant" do
    CATALOG.each do |name|
      expect(Object.const_defined?(name)).to be(true), "missing constant #{name}"
    end
  end

  it "passes the ENV guard" do
    stdout, stderr, status = Open3.capture3("bin/check_env", chdir: Rails.root.to_s)
    expect(status).to be_success, "bin/check_env failed:\n#{stdout}\n#{stderr}"
  end
end
