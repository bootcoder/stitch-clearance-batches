class AddActiveBooleanToClearanceBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :clearance_batches, :active, :boolean, default: true
  end
end
