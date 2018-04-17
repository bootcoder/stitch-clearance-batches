require 'csv'

class ClearanceBatchesController < ApplicationController

  def index
    batches = ClearanceBatch.in_progress.order(updated_at: :desc)
    @in_progress_batches = batches.to_a << ClearanceBatch.new
    @clearance_batches  = ClearanceBatch.completed
  end

  def show
    @clearance_batch = ClearanceBatch.includes(:items).find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "clearance_batch_#{@clearance_batch.id}",
               template: 'clearance_batches/_show.html.erb',
               title: "clearance_batch_#{@clearance_batch.id}"
      end
      format.csv
    end
  end

  def create
    alert_messages     = []

    if clearance_params[:csv_file]
      clearancing_status = ClearancingService.new.process_file(clearance_params[:csv_file].tempfile)
      clearance_batch    = clearancing_status.clearance_batch
      if clearance_batch.persisted?
        flash[:notice]  = "#{clearance_batch.items.count} items clearanced in batch #{clearance_batch.id}"
      else
        alert_messages << "No new clearance batch was added"
      end
      if clearancing_status.errors.any?
        alert_messages << "#{clearancing_status.errors.count} item ids raised errors and were not clearanced"
        clearancing_status.errors.each {|error| alert_messages << error }
      end

    elsif clearance_params[:batch_id]
      batch = clearance_params[:batch_id] == "new" ? ClearanceBatch.new : ClearanceBatch.find_by(id: clearance_params[:batch_id])
      item = Item.find_by(id: clearance_params[:item_id])
      if item && batch.save
        item.clearance!
        batch.items << item
        if item.save
          flash[:notice]  = "Item #{item.id} Clearanced Successfully!"
        else
          alert_messages << "Could not clearance Item #{item.id}"
        end
      else
        alert_messages << 'Could not find an Item with that ID, please try again.'
      end
    end

    flash[:alert] = alert_messages.join("<br/>") if alert_messages.any?
    redirect_to action: :index
  end

  private

  def clearance_params
    params.permit(:csv_file, :item_id, :batch_id)
  end

end
