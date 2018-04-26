# NOTE: DEBUGGER
system 'clear'

class ClearanceBatchesController < ApplicationController


  # NOTE: Split batches into two groups for active and completed
  # Started out with several Ajax views but ultimately decided things were small
  # enough to simply re-render index asynchronously
  def index
    @active_batches = ClearanceBatch.active
    @completed_batches  = ClearanceBatch.completed

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @clearance_batch = ClearanceBatch.includes(:items).find(params[:id])
    @sort_options = {
      'id-asc' => {attr: 'id', text: 'ID UP'},
      'id-desc' => {attr: 'id', text: 'ID DN', desc: true},
      'size-asc' => {attr: 'size', text: 'Size UP'},
      'size-desc' => {attr: 'size', text: 'Size DN', desc: true},
      'color-asc' => {attr: 'color', text: 'Color UP'},
      'color-desc' => {attr: 'color', text: 'Color DN', desc: true},
      'price-asc' => {attr: 'price_sold', text: 'Price UP'},
      'price-desc' => {attr: 'price_sold', text: 'Price DN', desc: true},
      'style-asc' => {attr: 'style_id', text: 'Style UP'},
      'style-desc' => {attr: 'style_id', text: 'Style DN', desc: true},
      'date-asc' => {attr: 'sold_at', text: 'Date UP'},
      'date-desc' => {attr: 'sold_at', text: 'Date DN', desc: true},
      'updated-at-asc' => {attr: 'updated_at', text: 'Updated UP'},
      'updated-at-desc' => {attr: 'updated_at', text: 'Updated DN', desc: true},
    }

    @select_options = []
    @sort_options.keys.map { |e| @select_options << [@sort_options[e][:text], e] }

    if @clearance_batch
      @items = what_the_sort(@clearance_batch, clearance_params[:sort])
      respond_to do |format|
        format.html
        format.csv
        format.js
        format.pdf do
          render pdf: "clearance_batch_#{@clearance_batch.id}",
                 template: 'clearance_batches/_report.html.erb',
                 layout: 'pdf.html',
                 title: "clearance_batch_#{@clearance_batch.id}"
        end
      end
    else
      # NOTE: Handle NOT FOUND
    end
  end

  # NOTE: handles create for csv and item into a batch.
  # feel kinda icky about the nonRESTfullness but didn't feel
  # an Items controller was the solution either
  def create

    # CSV or batch ID required - batch_id may be 'new'
    # Item ID or batch ID required
    if !clearance_params[:csv_file] && ( clearance_params[:item_id] == '' || !clearance_params[:item_id] )
      flash[:alert] = "You must enter an Item id or CSV file to clearance items"
    else
      # ClearancinService will figure out what to do with our input.
      service = ClearancingService.new(
        file: clearance_params[:csv_file],
        item_id: clearance_params[:item_id],
        batch: ClearanceBatch.find_by(id: clearance_params[:batch_id])).execute!
      # CSV batches are automatically closed after processing.
      if service.batch.persisted? && clearance_params[:csv_file]
        service.batch.update_attributes(active: false)
      end

      # Put together various flash msgs for after action report.
      flash[:alert] = service.errors.join("<br/>") if service.errors.any?
      flash[:notice] = service.notices.join("<br/>") if service.notices.any?
    end
    redirect_to action: :index
  end

  def update
    batch = ClearanceBatch.find_by(id: params[:id])

    # No valid batch passed
    if !batch
      flash[:alert] = "Could not find batch id #{params[:id]}."

    # Attempting to close an already closed batch
    elsif !batch.active && clearance_params[:close_batch]
      flash[:alert] = "Batch id #{params[:id]} is already closed."

    # Attempting to open an already active branch
    elsif batch.active && clearance_params[:activate_batch]
      flash[:alert] = "Batch id #{params[:id]} is already open."

    # Close Success Case
    elsif clearance_params[:close_batch]
      batch.update_attributes(active: false)
      flash[:notice] = "Clearance Batch #{batch.id} successfully closed."

    # Activated Success Case
    elsif clearance_params[:activate_batch]
      batch.update_attributes(active: true)
      flash[:notice] = "Clearance Batch #{batch.id} reactivated."

    # Fallthrough catch flashes general error
    else
      flash[:alert] = "Failed to update batch #{params[:id]}, refresh and try again."

    end

    redirect_to action: :index
  end

  private

  # NOTE: Added Strong params because..... That's what you do. :-)
  def clearance_params
    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch, :sort)
  end

  def what_the_sort(batch, sort)
    sort ||= 'updated-at-desc'
    return batch.sort_items_by(@sort_options[sort][:attr], @sort_options[sort][:desc])
    # case sort
    # when 'id_asc'
    #   return batch.sort_items_by('id')
    # when 'id-desc'
    #   return batch.sort_items_by('id', true)
    # else
    #   return batch.sort_items_by('updated_at', true)
    # end
  end

end
