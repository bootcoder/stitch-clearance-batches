module CapybaraHelper

  include Capybara::DSL

  def upload_batch_file(file_name)
    visit "/"
    within('table.clearance_batches') do
      expect(page).not_to have_content(/Clearance Batch \d+/)
    end
    attach_file("Or upload CSV batch file", file_name)
    click_button "Clearance!"
    self
  end

  def upload_single_item
    visit '/'
    within('table.clearance_batches') do
      expect(page).not_to have_content(/Clearance Batch \d+/)
    end
    fill_in('item_id', with: '1')
    click_button 'Clearance!'
    within('table.open_batches') do
      expect(page.all('tr').count).to eq 2
      expect(page.all('tr')[1].all('td')[2]).to have_content "1"
      expect(page).to have_content "Open Batch #{ClearanceBatch.last.id}"
    end
    self
  end

  def upload_invalid_item(input)
    upload_single_item
    visit '/'
    fill_in('item_id', with: input)
    click_button 'Clearance!'
    expect(page).to have_content('Could not find an Item with that ID, please try again.')
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
