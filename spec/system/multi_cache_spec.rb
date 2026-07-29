# spec/system/multi_cache_spec.rb
require "rails_helper"

RSpec.describe "Rails Cache Stores & Hybrid Cache", type: :system do
  let(:cache_key) { "test_hybrid_cache_key_#{SecureRandom.hex(4)}" }

  after(:each) do
    # System / Store Cleanup
    Rails.local_cache.delete("rspec_local_key")
    Rails.local_cache.delete("rspec_local_fetch_key")
    Rails.local_cache.delete("rspec_independent_key")
    Rails.global_cache.delete("rspec_global_key")
    Rails.global_cache.delete("rspec_global_fetch_key")
    Rails.global_cache.delete("rspec_independent_key")

    # Hybrid Cache Cleanup (pass sync: false so cleanup doesn't fire extra invalidations)
    Rails.hybrid_cache.delete(cache_key, sync: false) if Rails.hybrid_cache.respond_to?(:delete)
  end

  # ===========================================================================
  # 1. LOCAL CACHE (Solid Cache / SQLite)
  # ===========================================================================
  describe "Rails.local_cache (Solid Cache / SQLite)" do
    it "reads and writes string values" do
      Rails.local_cache.write("rspec_local_key", "hello local")
      expect(Rails.local_cache.read("rspec_local_key")).to eq("hello local")
    end

    it "deletes values" do
      Rails.local_cache.write("rspec_local_key", "to delete")
      Rails.local_cache.delete("rspec_local_key")
      expect(Rails.local_cache.read("rspec_local_key")).to be_nil
    end

    it "fetches and caches a block result" do
      result = Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { "computed" }
      expect(result).to eq("computed")

      cached = Rails.local_cache.read("rspec_local_fetch_key")
      expect(cached).to eq("computed")
    end

    it "returns cached value on subsequent fetch" do
      call_count = 0
      Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { call_count += 1; "first" }
      result = Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { call_count += 1; "second" }

      expect(result).to eq("first")
      expect(call_count).to eq(1)
    end

    it "checks key existence" do
      expect(Rails.local_cache.exist?("rspec_local_key")).to be false
      Rails.local_cache.write("rspec_local_key", "exists")
      expect(Rails.local_cache.exist?("rspec_local_key")).to be true
    end
  end

  # ===========================================================================
  # 2. GLOBAL CACHE (Redis)
  # ===========================================================================
  describe "Rails.global_cache (Redis)" do
    it "successfully connects to the Redis server backend" do
      expect {
        Kredis.redis.ping
      }.not_to raise_error
    end

    it "reads and writes string values" do
      Rails.global_cache.write("rspec_global_key", "hello global")
      expect(Rails.global_cache.read("rspec_global_key")).to eq("hello global")
    end

    it "deletes values" do
      Rails.global_cache.write("rspec_global_key", "to delete")
      Rails.global_cache.delete("rspec_global_key")
      expect(Rails.global_cache.read("rspec_global_key")).to be_nil
    end

    it "fetches and caches a block result" do
      result = Rails.global_cache.fetch("rspec_global_fetch_key", expires_in: 60) { "global computed" }
      expect(result).to eq("global computed")

      cached = Rails.global_cache.read("rspec_global_fetch_key")
      expect(cached).to eq("global computed")
    end

    it "checks key existence" do
      expect(Rails.global_cache.exist?("rspec_global_key")).to be false
      Rails.global_cache.write("rspec_global_key", "exists")
      expect(Rails.global_cache.exist?("rspec_global_key")).to be true
    end
  end

  # ===========================================================================
  # 3. STORE INDEPENDENCE
  # ===========================================================================
  describe "store independence" do
    it "stores the same key independently in local and global caches" do
      Rails.local_cache.write("rspec_independent_key", "local value")
      Rails.global_cache.write("rspec_independent_key", "global value")

      expect(Rails.local_cache.read("rspec_independent_key")).to eq("local value")
      expect(Rails.global_cache.read("rspec_independent_key")).to eq("global value")
    end
  end

  # ===========================================================================
  # 4. HYBRID CACHE (L1 + L2)
  # ===========================================================================
  describe "Rails.hybrid_cache" do
    describe ".fetch" do
      context "when cache miss (key does not exist in L1 or L2)" do
        it "executes the block and stores the value in both L1 and L2" do
          block_executed = false

          result = Rails.hybrid_cache.fetch(cache_key, expires_in: 5.minutes) do
            block_executed = true
            "fresh_data"
          end

          expect(result).to eq("fresh_data")
          expect(block_executed).to be true

          # Verify values in underlying cache layers
          expect(Rails.local_cache.read(cache_key)).to eq("fresh_data")
          expect(Rails.global_cache.read(cache_key)).to eq("fresh_data")
        end
      end

      context "when cache hit in L1 (Local SQLite)" do
        before do
          Rails.local_cache.write(cache_key, "cached_in_l1")
        end

        it "returns the cached value without executing the block" do
          block_executed = false

          result = Rails.hybrid_cache.fetch(cache_key) do
            block_executed = true
            "new_data"
          end

          expect(result).to eq("cached_in_l1")
          expect(block_executed).to be false
        end
      end

      context "when cache miss in L1 but cache hit in L2 (Redis)" do
        before do
          Rails.local_cache.delete(cache_key)
          Rails.global_cache.write(cache_key, "cached_in_l2")
        end

        it "returns the L2 value, warms up L1, and does not execute the block" do
          block_executed = false

          result = Rails.hybrid_cache.fetch(cache_key) do
            block_executed = true
            "new_data"
          end

          expect(result).to eq("cached_in_l2")
          expect(block_executed).to be false

          # Verify L1 was warmed up
          expect(Rails.local_cache.read(cache_key)).to eq("cached_in_l2")
        end
      end
    end

    describe ".read" do
      it "returns nil when key does not exist" do
        expect(Rails.hybrid_cache.read("non_existent_key")).to be_nil
      end

      it "reads from L1 if present" do
        Rails.local_cache.write(cache_key, "value_in_l1")
        expect(Rails.hybrid_cache.read(cache_key)).to eq("value_in_l1")
      end

      it "reads from L2 and populates L1 if L1 is empty" do
        Rails.local_cache.delete(cache_key)
        Rails.global_cache.write(cache_key, "value_in_l2")

        expect(Rails.hybrid_cache.read(cache_key)).to eq("value_in_l2")
        expect(Rails.local_cache.read(cache_key)).to eq("value_in_l2")
      end
    end

    describe ".write" do
      it "writes value to both L1 and L2 and triggers Pub/Sub invalidation" do
        expect(Rails.hybrid_cache).to receive(:publish_invalidation).with("write", cache_key).and_call_original

        Rails.hybrid_cache.write(cache_key, "write_value")

        expect(Rails.local_cache.read(cache_key)).to eq("write_value")
        expect(Rails.global_cache.read(cache_key)).to eq("write_value")
      end

      it "skips Pub/Sub invalidation when sync: false is passed" do
        expect(Rails.hybrid_cache).not_to receive(:publish_invalidation)

        Rails.hybrid_cache.write(cache_key, "quiet_value", sync: false)
      end
    end

    describe ".delete" do
      before do
        Rails.local_cache.write(cache_key, "to_be_deleted")
        Rails.global_cache.write(cache_key, "to_be_deleted")
      end

      it "removes the key from both L1 and L2 and publishes invalidation signal" do
        expect(Rails.hybrid_cache).to receive(:publish_invalidation).with("delete", cache_key).and_call_original

        Rails.hybrid_cache.delete(cache_key)

        expect(Rails.local_cache.read(cache_key)).to be_nil
        expect(Rails.global_cache.read(cache_key)).to be_nil
      end
    end

    # =========================================================================
    # 5. PUB/SUB BROADCAST & LISTENER INTEGRATION
    # =========================================================================
    describe "Pub/Sub Broadcast & Listener" do
      before do
        Rails.local_cache.write(cache_key, "stale_local_data")
      end

      describe "broadcasting invalidation messages" do
        it "triggers publish_invalidation when writing to hybrid_cache" do
          expect(Rails.hybrid_cache).to receive(:publish_invalidation)
            .with("write", cache_key)
            .and_call_original

          Rails.hybrid_cache.write(cache_key, "new_value")
        end

        it "triggers publish_invalidation when deleting from hybrid_cache" do
          expect(Rails.hybrid_cache).to receive(:publish_invalidation)
            .with("delete", cache_key)
            .and_call_original

          Rails.hybrid_cache.delete(cache_key)
        end

        it "does not trigger publish_invalidation when sync: false" do
          expect(Rails.hybrid_cache).not_to receive(:publish_invalidation)

          Rails.hybrid_cache.write(cache_key, "quiet_value", sync: false)
          Rails.hybrid_cache.delete(cache_key, sync: false)
        end
      end

      describe "listener handling" do
        it "purges L1 cache when invalidation is triggered for a key" do
          # Test the invalidation effect on L1 directly
          expect(Rails.local_cache.read(cache_key)).to eq("stale_local_data")

          # Simulating invalidation action directly through hybrid_cache delete/write
          Rails.hybrid_cache.delete(cache_key, sync: false)

          expect(Rails.local_cache.read(cache_key)).to be_nil
        end
      end
    end
  end
end