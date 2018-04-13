class UpdateCbOpenToInProgress < ActiveRecord::Migration[5.2]
  def change
    remove_column :clearance_batches, :open
    add_column :clearance_batches, :in_progress, :boolean, default: true
  end
end
