module CapybaraHelper

  include Capybara::DSL

  def upload_batch_file(file_name)
    visit "/"
    within('table.clearance_batches') do
      expect(page.all('tr').count).to eq 1
      expect(page).not_to have_content(/Clearanced Batch \d+/)
    end
    attach_file("csv_file", file_name)
    click_button "Clearance!"
    wait_for_ajax
    self
  end

  def upload_single_item(item)
    visit '/'
    fill_in('item_id', with: item.id)
    find('#submit_clearance').click
    wait_for_ajax
    self
  end

  def upload_first_item(item = Item.first)
    visit '/'
    within('table.clearance_batches') do
      expect(page).not_to have_content(/Clearance Batch \d+/)
      expect(page).not_to have_content(/In Progress Batch \d+/)
    end
    fill_in('item_id', with: item.id)
    find('#submit_clearance').click
    wait_for_ajax
    within('table.in_progress_batches') do
      # This hard coding of elements seems hacky, would love some advice on a better approach.
      expect(page.all('tr').count).to eq 2
      expect(page.all('tr')[1].all('td')[2]).to have_content "1"
      expect(page).to have_content "In Progress Batch #{ClearanceBatch.last.id}"
    end
    expect(page).to have_content("Item #{item.id} Clearanced Successfully!")
    self
  end

  def upload_invalid_item(input)
    upload_first_item
    visit '/'
    fill_in('item_id', with: input)
    click_button 'Clearance!'
    wait_for_ajax
    expect(page).to have_selector '.alert'
    expect(Item.find(other_item.id).status).to eq 'sellable'
    self
  end

  def pdf_to_pdf
    temp_pdf = Tempfile.new('pdf')
    temp_pdf << page.source.force_encoding('UTF-8')
    reader = PDF::Reader.new(temp_pdf)
    pdf_text = reader.pages.map(&:text)
    temp_pdf.close
    page.driver.response.instance_variable_set('@body', pdf_text)
  end

end
