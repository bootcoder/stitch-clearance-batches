module CapybaraHelper

  include Capybara::DSL

  def upload_batch_file(file_name)
    visit "/"
    within('table.completed_table') do
      expect(page.all('tr').count).to eq 0
      expect(page).not_to have_content(/Clearanced Batch \d+/)
      expect(page).not_to have_content(/Active Batch \d+/)
    end
    attach_file("csv_file", file_name)
    click_button "Clearance CSV!"
    wait_for_ajax
    self
  end

  def upload_single_item(item)
    visit '/'
    fill_in('item_id', with: item.id)
    find('#submit_item').click
    wait_for_ajax
    self
  end

  def upload_first_item(item = Item.first)
    visit '/'
    within('table.completed_table') do
      expect(page).not_to have_content(/Clearance Batch \d+/)
      expect(page).not_to have_content(/Active Batch \d+/)
    end

    fill_in('item_id', with: item.id)
    find('#submit_item').click
    wait_for_ajax

    within('table.active_table') do
      # NOTE: This hard coding of elements seems hacky,
      # would love some advice on a better approach.
      # This creates a very tight coupling of spec and view.
      expect(page.all('tr').count).to eq 1
      expect(page.all('tr')[0].all('td')[1]).to have_content "1"
      expect(page).to have_content "Active Batch #{ClearanceBatch.last.id}"
    end
    expect(page).to have_selector '.alert-info'
    expect(page).to have_content("Item #{item.id} Clearanced Successfully!")
    self
  end

  def upload_invalid_item(input)
    upload_first_item
    visit '/'
    fill_in('item_id', with: input)
    click_button 'Clearance Item!'
    wait_for_ajax
    expect(page).to have_selector '.alert-danger'
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
