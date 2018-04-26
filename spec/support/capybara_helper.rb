module CapybaraHelper

  # NOTE: Self contained helpers return self and are chainable.
  # They also assert expectation of their own
  # This is a great way to clean up / DRY out feature specs.

  include Capybara::DSL

  def check_active_item_count(count_1, count_2)
    within('table.active_table') do
      expect(page.all('tr').count).to eq 2
      expect(page.all('tr')[0].all('td')[1]).to have_content count_1.to_s
      expect(page.all('tr')[1].all('td')[1]).to have_content count_2.to_s
      expect(page).to have_content "Active Batch #{ClearanceBatch.first.id}"
      expect(page).to have_content "Active Batch #{ClearanceBatch.last.id}"
      self
    end
  end

  def check_count_all_rows(completed_count, active_count)
    expect(page.all('table.completed_table tr').count).to eq completed_count
    expect(page.all('table.active_table tr').count).to eq active_count
    self
  end

  def check_report_first_tr_has_item(item)
    within('#batch-report tbody') do
      expect(page.all('tr').count).to eq 5
      expect(page.first('tr').first('th')).to have_content item.id
    end
  end

  def report_select_sort_by(option_idx, item)
    visit '/clearance_batches/1'
    within('#report-header') do
      find('#sort-select').find(:xpath, "option[#{option_idx}]").select_option
      find('#btn-sort-select').click
      wait_for_ajax
    end
    self
  end

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

  def upload_single_item_to_batch(item_id, batch_id)
    find('#batch_select').find(:option, batch_id).select_option
    fill_in('item_id', with: item_id)
    click_button 'Clearance Item!'
    wait_for_ajax
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
