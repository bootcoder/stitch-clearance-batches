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

  def upload_item
    visit '/'
    within('table.clearance_batches') do
      expect(page).not_to have_content(/Clearance Batch \d+/)
    end
    fill_in('clearance_item', with: '12345')
    click_button 'Clearance!'
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
