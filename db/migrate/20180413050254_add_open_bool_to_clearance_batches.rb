class AddOpenBoolToClearanceBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :clearance_batches, :open, :boolean, default: true
  end
end
