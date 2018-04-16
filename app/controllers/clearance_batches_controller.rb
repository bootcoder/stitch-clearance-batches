class ClearanceBatchesController < ApplicationController


  # NOTE: Split batches into two groups for in_progress and completed
  # Started out with several Ajax views but ultimately decided things were small
  # enough to simply re-render index asynchronously
  def index
    @in_progress_batches = ClearanceBatch.in_progress
    @completed_batches  = ClearanceBatch.completed

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @clearance_batch = ClearanceBatch.includes(:items).find(params[:id])

    respond_to do |format|
      format.html
      format.csv
      format.pdf do
        render pdf: "clearance_batch_#{@clearance_batch.id}",
               template: 'clearance_batches/_show.html.erb',
               layout: 'pdf.html',
               title: "clearance_batch_#{@clearance_batch.id}"
      end
    end
  end

  def create
    # NOTE: handles create for csv and item into a batch.
    # feel kinda icky about the nonRESTfullness but didn't feel
    # an Items controller was the solution either

    # CSV or batch ID required - batch_id may be 'new'
    # Item ID or batch ID required
    ep clearance_params
    if !clearance_params[:csv_file] && !clearance_params[:batch_id]
      flash[:alert] = "You must enter an Item id or CSV file to clearance items"
    elsif clearance_params[:batch_id] && clearance_params[:item_id] == ''
      flash[:alert] = "You must enter an Item id or CSV file to clearance items"
    else
      service = ClearancingService.new(
        file: clearance_params[:csv_file],
        item_id: clearance_params[:item_id],
        batch: ClearanceBatch.find_by(id: clearance_params[:batch_id]))

      # CSV batches are automatically closed after processing.
      if service.batch.persisted? && clearance_params[:csv_file]
        service.batch.update_attributes(in_progress: false)
      end

      # Put together various flash msgs for after action report.
      flash[:alert] = service.errors.join("<br/>") if service.errors.any?
      flash[:notice] = service.notices.join("<br/>") if service.notices.any?
    end
    redirect_to action: :index
  end

  def update
    batch = ClearanceBatch.find_by(id: params[:id])

    if !batch
      flash[:alert] = "Could not find batch id #{params[:id]}."

    elsif !batch.in_progress && clearance_params[:close_batch]
      flash[:alert] = "Batch id #{params[:id]} is already closed."

    elsif batch.in_progress && clearance_params[:open_batch]
      flash[:alert] = "Batch id #{params[:id]} is already open."

    elsif clearance_params[:close_batch]
      batch.update_attributes(in_progress: false)
      flash[:notice] = "Clearance Batch #{batch.id} successfully closed."

    elsif clearance_params[:open_batch]
      batch.update_attributes(in_progress: true)
      flash[:notice] = "Clearance Batch #{batch.id} reopened."

    else
      flash[:alert] = "Failed to update batch #{params[:id]}, refresh and try again."

    end

    redirect_to action: :index
  end

  private

  def clearance_params
    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :open_batch)
  end

end
