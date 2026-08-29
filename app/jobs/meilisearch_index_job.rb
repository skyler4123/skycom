class MeilisearchIndexJob < ApplicationJob
  queue_as :meilisearch

  def perform(model_name, id, remove = false)
    klass = model_name.safe_constantize
    raise ArgumentError, "Unknown or non-AR model: #{model_name}" unless klass && klass < ApplicationRecord

    record = klass.find_by(id: id)
    if record
      remove ? record.ms_remove_from_index!(true) : record.ms_index!(true)
    else
      klass.ms_remove_from_index!(klass.new(id: id), true)
    end
  end
end