# frozen_string_literal: true

require "rails_helper"

# Unit-level coverage for the action-scoping behavior of
# Companies::FeatureGatingConcern#feature_key. End-to-end coverage for the
# real REST actions (branches with only: [:new, :create]) lives in
# spec/requests/companies/feature_gating_spec.rb.
RSpec.describe Companies::FeatureGatingConcern do
  describe "feature_key" do
    it "stores the feature key when a key is passed" do
      klass = Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch
      end

      expect(klass.feature_key).to eq("multi_branch")
    end

    it "returns the stored key when called without arguments" do
      klass = Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch
      end

      expect(klass.feature_key).to eq("multi_branch")
    end

    it "leaves only/except nil for a bare feature_key (backward compatible)" do
      klass = Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch
      end

      expect(klass.feature_key_only).to be_nil
      expect(klass.feature_key_except).to be_nil
    end
  end

  describe "feature_key with only:" do
    let(:klass) do
      Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch, only: [ :index, :custom_action ]
      end
    end

    it "normalizes symbol action names to strings" do
      expect(klass.feature_key_only).to eq([ "index", "custom_action" ])
      expect(klass.feature_key_except).to be_nil
    end

    it "exempts actions not listed in only:" do
      controller = klass.new
      allow(controller).to receive(:action_name).and_return("create")
      expect(controller.send(:feature_gate_exempted?)).to be true
    end

    it "gates a default REST action listed in only:" do
      controller = klass.new
      allow(controller).to receive(:action_name).and_return("index")
      expect(controller.send(:feature_gate_exempted?)).to be false
    end

    it "gates a custom developer action listed in only:" do
      controller = klass.new
      allow(controller).to receive(:action_name).and_return("custom_action")
      expect(controller.send(:feature_gate_exempted?)).to be false
    end
  end

  describe "feature_key with except:" do
    let(:klass) do
      Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch, except: [ :custom_action ]
      end
    end

    it "normalizes symbol action names to strings" do
      expect(klass.feature_key_except).to eq([ "custom_action" ])
      expect(klass.feature_key_only).to be_nil
    end

    it "exempts the custom action listed in except:" do
      controller = klass.new
      allow(controller).to receive(:action_name).and_return("custom_action")
      expect(controller.send(:feature_gate_exempted?)).to be true
    end

    it "gates actions not listed in except:" do
      controller = klass.new
      allow(controller).to receive(:action_name).and_return("index")
      expect(controller.send(:feature_gate_exempted?)).to be false
    end
  end

  describe "feature_key with both only: and except:" do
    let(:klass) do
      Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch, only: [ :index, :custom_action ], except: [ :custom_action ]
      end
    end

    it "applies the intersection (only AND NOT except)" do
      expect(klass.feature_key_only).to eq([ "index", "custom_action" ])
      expect(klass.feature_key_except).to eq([ "custom_action" ])

      controller = klass.new
      allow(controller).to receive(:action_name).and_return("custom_action")
      expect(controller.send(:feature_gate_exempted?)).to be true

      allow(controller).to receive(:action_name).and_return("index")
      expect(controller.send(:feature_gate_exempted?)).to be false

      allow(controller).to receive(:action_name).and_return("create")
      expect(controller.send(:feature_gate_exempted?)).to be true
    end
  end

  describe "feature_gate_exempted? with string action names" do
    let(:klass) do
      Class.new(ApplicationController) do
        include Companies::FeatureGatingConcern
        feature_key :multi_branch, only: [ "index" ]
      end
    end

    it "normalizes string action names too" do
      expect(klass.feature_key_only).to eq([ "index" ])

      controller = klass.new
      allow(controller).to receive(:action_name).and_return("index")
      expect(controller.send(:feature_gate_exempted?)).to be false

      allow(controller).to receive(:action_name).and_return("show")
      expect(controller.send(:feature_gate_exempted?)).to be true
    end
  end
end
