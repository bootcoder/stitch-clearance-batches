class ClearanceBatch < ActiveRecord::Base

  def title
    self.in_progress ? "In Progress Batch #{self.id}" : "Batch #{self.id}"
  end


  has_many :items

  scope :in_progress, -> { includes(:items).where(in_progress: true).order(updated_at: :desc) }
  scope :completed, -> { includes(:items).where(in_progress: false).order(updated_at: :desc) }

end
