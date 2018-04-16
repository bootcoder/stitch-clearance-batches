require 'csv'

module ClearanceBatchHelper


  # NOTE: been looking all over for how to make this work
  # the rub is I use it in the form for
  # options_from_collection_for_select(@in_progress_batches, :id, :title, @in_progress_batches.first.id.to_s)
  # and I cannot figure out how to replace :title with this helper, as the only way I can find to get the id involves diving deep into underlying rails object.
  # I'll look at it some more, but I still believe a virtual attr on the model is both the best approach and in line with the 'Rails Way'
  def title(id)
    obj = ClearanceBatch.find(id)
    obj.in_progress ? "In Progress Batch #{obj.id}" : "Clearanced Batch #{obj.id}"
  end

  def generate_csv_report(items)
    attrs = csv_headers(items.first)
    CSV.generate(headers: true) do |row|
      row << attrs
      items.each do |item|
        row << csv_attrs(item).values
      end
    end
  end

end
