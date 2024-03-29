class Item < ActiveRecord::Base

  CLEARANCE_PRICE_PERCENTAGE  = BigDecimal.new("0.75")

  belongs_to :style
  belongs_to :clearance_batch, optional: true, touch: true

  validates_presence_of :size, :color, :status

  scope :sellable, -> { where(status: 'sellable') }

  def clearance!
    # NOTE: Your original code failed to set sold_at correctly. This seemed like the place to do it.
    update_attributes!(status: 'clearanced',
                       price_sold: style.wholesale_price * CLEARANCE_PRICE_PERCENTAGE,
                       sold_at: DateTime.now)
  end

end
