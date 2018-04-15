class ClearanceBatch < ActiveRecord::Base

  def title
    self.in_progress ? "In Progress Batch #{self.id}" : "Clearanced Batch #{self.id}"
  end


  has_many :items

  scope :in_progress, -> { where(in_progress: true) }
  scope :completed, -> { where(in_progress: false) }

end
