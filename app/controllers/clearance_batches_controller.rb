require 'csv'

class ClearanceBatchesController < ApplicationController

  def index
    @in_progress_batches = ClearanceBatch.in_progress.order(updated_at: :desc)
    @clearance_batches  = ClearanceBatch.completed
    respond_to do |format|
      format.html
      format.js
    end
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

  def update
    batch = ClearanceBatch.find(params[:id])
    if clearance_params[:close_batch] && batch
      batch.update_attributes(in_progress: false)
      flash[:notice] = "Clearance Batch #{batch.id} successfully closed"
    else
      flash[:alert] = "Error closing batch #{params[:id]}, refresh and try again."
    end
    redirect_to action: :index
  end

  def create
    alert_messages     = []
    notice_messages    = []

    if clearance_params[:csv_file]
      clearancing_status = ClearancingService.new.process_file(clearance_params[:csv_file].tempfile)
      batch    = clearancing_status.batch
      if batch.persisted?
        batch.update_attributes(in_progress: false)
        notice_messages << "#{batch.items.count} items clearanced in batch #{batch.id}"
      else
        alert_messages << "No new clearance batch was added"
      end
      if clearancing_status.errors.any?
        alert_messages << "#{clearancing_status.errors.count} item ids raised errors and were not clearanced"
        clearancing_status.errors.each {|error| alert_messages << error }
      end

    elsif clearance_params[:batch_id]
      clearancing_status = ClearancingService.new.process_item(
        clearance_params[:item_id],
        ClearanceBatch.find_by(id: clearance_params[:batch_id]))
      batch = clearancing_status.batch
      if clearancing_status.errors.any?
        clearancing_status.errors.each {|error| alert_messages << error }
      elsif batch.save
        notice_messages << "Item #{clearance_params[:item_id]} Clearanced Successfully!"
      else
        alert_messages << "No new clearance batch was added"
      end

    end
      flash[:alert] = alert_messages.join("<br/>") if alert_messages.any?
      flash[:notice] = notice_messages.join("<br/>") if notice_messages.any?
      redirect_to action: :index
    # respond_to do |format|
    #   format.html { }
    #   format.js
    # end
  end

  private

  def clearance_params
    params.permit(:csv_file, :item_id, :batch_id, :close_batch)
  end

end
