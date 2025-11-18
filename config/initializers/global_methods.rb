module Kernel
  def random(probability = 0.5)
    # Return immediately if no block is given to prevent errors
    return unless block_given?

    # Execute the block if the random float is within the probability
    yield if rand < probability
  end
end
