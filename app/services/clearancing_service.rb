class ClearancingService

  # NOTE: errors and notices can be appended outside the service.
  attr_accessor :errors, :notices
  attr_reader :batch, :items

  # NOTE: Clean up usage significantly utilizing init.
  # This refactor also allowed for a considerable reduction in controller code.
  # As the service now seamlessly handles both data types.
  def initialize(args)

    item_id             = args[:item_id]
    @batch              = args[:batch] || ClearanceBatch.new
    @file               = args[:file]
    @errors             = []
    @notices            = []
    @batch_ids          = []

    process_csv if @file
    process_item(item_id) if item_id && !@file

  end

  # NOTE: Originally I included these calls within init above.
  # Extracted here for a clearer separation of concerns.
  def execute!
    clearance_items!
    generate_report
    return self
  end

private

  # NOTE: Formerly #process_file, now simply processes each item
  # Also extracted the tempfile dependency from the controller as this is the only place it is used.
  def process_csv
    @file = @file.tempfile
    CSV.foreach(@file, headers: false) { |row| process_item(row[0].to_i) }
  end

  # NOTE: Sets an instance var, checks against error states, adds to batch_ids
  def process_item(item_id)
    @item_id = item_id.to_i
    @batch_ids << @item_id unless precheck_clearancing_error
  end

  # NOTE: Primary function
  # Skip if no ID's
  # Lookup the item and clearance it.
  # Add item to batch and update notices
  def clearance_items!
    return if @batch_ids.empty?
    @batch.save!
    @batch_ids.each do |item_id|
      item = Item.find(item_id)
      item.clearance!
      # NOTE: Considered adding a catch here if the item fails to save.
      # Feels unneeded as the item cannot possibly have invalid state at this point.
      @batch.items << item
      @notices << "Item #{item_id} Clearanced Successfully!"
    end
  end

  # NOTE: Service previously handled generating Item msgs:
  # Extracted batch msgs from controller, to the service as well.
  # I feel the responsibility lies here and it's much cleaner
  # Ensures some notice or error is returned from the service
  def generate_report
    @notices << "#{ActionController::Base.helpers.pluralize(@batch_ids.count, 'Item')} clearanced into batch #{batch.id}" if batch.id
    @errors << "#{ActionController::Base.helpers.pluralize(@errors.count, 'id')} raised errors and were not clearanced" if errors.any?
    @errors << "No new clearance batch was added" unless batch.id
    @errors << "No Item or CSV passed" if !@item_id && !@file
  end

  # NOTE: Formerly #what_is_the_clearancing_error?
  # Lost the ? as the method does not return a boolean
  # Added a case for item which is already clearanced
  def precheck_clearancing_error
    potential_item = Item.find_by(id: @item_id)

    if !@item_id.is_a?(Integer) || @item_id == 0
      @errors << "Item id #{@item_id} is not valid"

    elsif potential_item && potential_item.status == 'clearanced'
      # NOTE: The catch at the end is there just to satisfy a spec condition. Not super happy about that.
      @errors << "Item id #{@item_id} already clearanced into Batch #{potential_item.clearance_batch.id if potential_item.clearance_batch}"

    elsif !potential_item
      @errors << "Item id #{@item_id} could not be found"

    elsif Item.sellable.where(id: @item_id).none?
      @errors << "Item id #{@item_id} could not be clearanced"

    else
      false

    end

  end

end
