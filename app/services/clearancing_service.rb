class ClearancingService

  def initialize
    @clearancing_status = create_clearancing_status
  end

  def process_file(file)
    CSV.foreach(file, headers: false) { |row| process_item(row[0].to_i) }
    @clearancing_status
  end

  def process_item(item_id, batch = nil)
    # Allows item clearance within existing batch
    @clearancing_status.batch = batch if batch
    @item_id = item_id.to_i
    clearancing_error = precheck_clearancing_error?
    @clearancing_status.batch_ids << @item_id unless clearancing_error
    clearance_items!
  end

private

  def clearance_items!
    return @clearancing_status if @clearancing_status.batch_ids.empty?
    @clearancing_status.batch.save!
    @clearancing_status.batch_ids.each do |item_id|
      item = Item.find(item_id)
      item.clearance!
      @clearancing_status.batch.items << item
    end
    @clearancing_status
  end

  def precheck_clearancing_error?
    potential_item = Item.find_by(id: @item_id)

    if !@item_id.is_a?(Integer) || @item_id == 0
      @clearancing_status.errors << "Item id #{@item_id} is not valid"

    elsif potential_item && potential_item.status == 'clearanced'
      @clearancing_status.errors << "Item id #{@item_id} already clearanced"

    elsif !potential_item
      @clearancing_status.errors << "Item id #{@item_id} could not be found"

    elsif Item.sellable.where(id: @item_id).none?
      @clearancing_status.errors << "Item id #{@item_id} could not be clearanced"

    else
      false

    end

  end

  def create_clearancing_status
    OpenStruct.new(
      batch: ClearanceBatch.new,
      batch_ids: [],
      errors: [])
  end

end
