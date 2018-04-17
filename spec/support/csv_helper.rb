require 'csv'
module CsvHelper

  # generates a CSV file based on an array of
  #   Item objects (for legit CSV rows)
  # or
  #   Arrays of strings (for bogus rows)
  def generate_csv_file(item_rows)
    tmp_file_name = "#{Rails.root}/tmp/batch_#{Time.now.to_i}.csv"
    CSV.open(tmp_file_name, "wb") do |csv|
      item_rows.each do |item_row|
        if item_row.kind_of?(Item)
          csv << [item_row.id, item_row.size, item_row.color, item_row.status, '', '', item_row.style_id, item_row.created_at, item_row.updated_at]
        else
          # assumes an array of strings
          csv << item_row
        end
      end
    end
    tmp_file_name
  end

  def generate_csv(item_rows)
    tmp_file_name = "#{Rails.root}/tmp/batch_#{Time.now.to_i}.csv"
    file = CSV.open(tmp_file_name, "wb") do |csv|
      item_rows.each do |item_row|
        if item_row.kind_of?(Item)
          csv << [item_row.id, item_row.size, item_row.color, item_row.status, '', '', item_row.style_id, item_row.created_at, item_row.updated_at]
        else
          # assumes an array of strings
          csv << item_row
        end
      end
    end
    filerep
  end

  def generate_item_csv_row(item)
    CSV.generate_line(item.attributes.values)
  end

end
