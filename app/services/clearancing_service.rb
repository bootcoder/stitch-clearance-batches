require 'csv'
require 'ostruct'
class ClearancingService

  def process_file(uploaded_file)
    clearancing_status      = create_clearancing_status
    CSV.foreach(uploaded_file, headers: false) do |row|
      potential_item_id = row[0].to_i
      clearancing_error = what_is_the_clearancing_error?(potential_item_id)
      if clearancing_error
        clearancing_status.errors << clearancing_error
      else
        clearancing_status.item_ids_to_clearance << potential_item_id
      end
    end
    clearance_items!(clearancing_status)
  end

  def process_item(item_id, batch)
    clearancing_status      = create_clearancing_status
    clearancing_status.batch = batch if batch
    item_id = item_id.to_i
    clearancing_error = what_is_the_clearancing_error?(item_id)
    if clearancing_error
      clearancing_status.errors << clearancing_error
    else
      clearancing_status.item_ids_to_clearance << item_id
    end
    clearance_items!(clearancing_status)
  end

private

  def clearance_items!(clearancing_status)
    if clearancing_status.item_ids_to_clearance.any?
      Item.transaction do
        clearancing_status.batch.save!
        clearancing_status.item_ids_to_clearance.each do |item_id|
          item = Item.find(item_id)
          item.clearance!
          clearancing_status.batch.items << item
        end
      end
    end
    clearancing_status
  end

  def what_is_the_clearancing_error?(potential_item_id)
    if potential_item_id.blank? || potential_item_id == 0 || !potential_item_id.is_a?(Integer)
      return "Item id #{potential_item_id} is not valid"
    end

    potential_item = Item.find_by(id: potential_item_id)

    if potential_item && potential_item.status == 'clearanced'
      return "Item #{potential_item_id} already clearanced"
    end

    if !potential_item
      return "Item id #{potential_item_id} could not be found"
    end

    if Item.sellable.where(id: potential_item_id).none?
      return "Item id #{potential_item_id} could not be clearanced"
    end

    return nil

  end

  def create_clearancing_status
    OpenStruct.new(
      batch: ClearanceBatch.new,
      item_ids_to_clearance: [],
      errors: [])
  end

end
