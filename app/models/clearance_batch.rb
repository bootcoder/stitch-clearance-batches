class ClearanceBatch < ActiveRecord::Base

  has_many :items

  scope :in_progress, -> { where(in_progress: true) }
  scope :completed, -> { where(in_progress: false) }

end
