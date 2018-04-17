class ClearanceBatch < ActiveRecord::Base

  def title
    self.active ? "Active Batch #{self.id}" : "Batch #{self.id}"
  end


  has_many :items

  scope :active, -> { includes(:items).where(active: true).order(updated_at: :desc) }
  scope :completed, -> { includes(:items).where(active: false).order(updated_at: :desc) }

end
