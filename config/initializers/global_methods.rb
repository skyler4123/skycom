module Kernel
  def random(probability = 0.5)
    # Return immediately if no block is given to prevent errors
    return unless block_given?

    # Execute the block if the random float is within the probability
    yield if rand < probability
  end

  # Caches the result of an ActiveRecord Relation
  def cache_query(relation, expires_in: 1.hour)
    # 1. Convert the Active Record relation to a raw SQL string.
    #    This handles the interpolation of values (e.g., "WHERE id = 5").
    sql = relation.to_sql

    # 2. Generate the MD5 hash of the SQL query.
    #    We use MD5 because it is fast and short.
    query_hash = Digest::MD5.hexdigest(sql)

    # 3. Build the dynamic key: ModelName/HashedQuery
    #    Example: "User/a1b2c3d4e5..."
    cache_key = "#{self.name}/#{query_hash}"

    # 4. Fetch from Rails Cache
    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      Rails.logger.info "⚡️ Cache Miss: Executing SQL for #{cache_key}"
      
      # IMPORTANT: We must call .to_a to execute the query 
      # and store the actual Array of records, not the Relation object.
      relation.to_a
    end
  end
end
