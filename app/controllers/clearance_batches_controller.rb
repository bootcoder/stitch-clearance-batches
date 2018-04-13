require 'csv'

class ClearanceBatchesController < ApplicationController

  def index
    @clearance_batches  = ClearanceBatch.all
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
    if clearance_params[:csv_batch_file]
      clearancing_status = ClearancingService.new.process_file(clearance_params[:csv_batch_file].tempfile)
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
    elsif clearance_params[:clearance_item_batch_id]
      batch = ClearanceBatch.find(clearance_params[:clearance_item_batch_id])
      @item = batch.items.new(clearance_params[:clearance_item])
      if @item.save
        flash[:notice]  = "Item Clearanced Successfully"
      else
        alert_messages << 'Thats how you know you fucked up...'
      end
    else
      batch = ClearanceBatch.create
      @item = Item.find_by(id: params[:clearance_item])
      if @item
        @item.clearance!
        batch.items << @item
        flash[:notice]  = "Item Clearanced Successfully"
      else
        alert_messages << 'Thats how you know you fucked up...'
      end
    end
    flash[:alert] = alert_messages.join("<br/>") if alert_messages.any?
    redirect_to action: :index
  end

  private

  def clearance_params
    params.permit(:csv_batch_file, :clearance_item, :clearance_item_batch_id)
  end

end
