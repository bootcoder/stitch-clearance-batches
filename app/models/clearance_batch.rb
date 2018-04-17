class ClearanceBatch < ActiveRecord::Base

  has_many :items

  scope :open, -> { where(open: true) }
  scope :completed, -> { where(open: false) }

end
