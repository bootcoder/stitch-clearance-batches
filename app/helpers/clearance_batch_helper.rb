require 'csv'

module ClearanceBatchHelper

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
