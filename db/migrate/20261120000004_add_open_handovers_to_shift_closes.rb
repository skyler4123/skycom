# frozen_string_literal: true

# Snapshot of the open handovers at close time so the printed report lists what
# was still waiting, not just a count that later changes.
class AddOpenHandoversToShiftCloses < ActiveRecord::Migration[8.0]
  def change
    add_column :shift_closes, :open_handovers_snapshot, :jsonb, default: [], null: false
  end
end
