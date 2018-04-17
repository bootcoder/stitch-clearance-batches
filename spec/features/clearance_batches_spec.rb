require "rails_helper"

describe "clearance_batch" do

  describe "INDEX", type: :feature do

    describe "see previous clearance batches" do

      let!(:clearance_batch_1) { FactoryBot.create(:clearance_batch) }
      let!(:clearance_batch_2) { FactoryBot.create(:clearance_batch) }
      let!(:clearance_batch_3) { FactoryBot.create(:clearance_batch) }

      it "displays a list of all past clearance batches" do
        visit "/"
        expect(page).to have_content("Completed Batches")
        within('table.completed_table') do
          expect(page).to have_content(clearance_batch_1.title)
          expect(page).to have_content(clearance_batch_2.title)
          expect(page).to have_content(clearance_batch_3.title)
        end
      end

    end

    describe 'displays report links in previous batches' do
      let!(:batch_1) {FactoryBot.create(:clearance_batch_with_items)}

      it "Batch has links to generate reports" do
        visit "/"
        within('table.completed_table') do
          within(first('.batch-row')) do
            pdf = find('.pdf-btn')
            csv = find('.csv-btn')
            html = find('.html-btn')
            expect(pdf.value).to eq 'PDF'
            expect(csv.value).to eq 'CSV'
            expect(html.value).to eq 'View'
          end
        end
      end
    end

    describe 'add a new clearance item', js: true do
      let!(:single_item) { FactoryBot.create(:item, color: 'gumdrop-glow') }
      let!(:other_item) { FactoryBot.create(:item, color: 'gumdrop-glow') }

      context 'VALID INPUT' do
        it 'allows a user to clearance a single item successfully' do
          upload_first_item
          expect(ClearanceBatch.last.items).to include single_item
        end
      end

      context 'INVALID INPUT' do
        it "'a' flashes error, does not alter DB" do
          upload_invalid_item("A")
          expect(page).to have_content "is not valid"
        end

        it "'nil' flashes error, does not alter DB" do
          upload_invalid_item('nil')
          expect(page).to have_content "is not valid"
        end

        it "789718972 flashes error, does not alter DB" do
          upload_invalid_item('789718972')
          expect(page).to have_content "Item id 789718972 could not be found"
        end

        it "JS flashes error, does not alter DB" do
          upload_invalid_item('<script>alert("bad internet, go to your room!");</script>')
          expect(page).to have_content 'is not valid'
        end

        it 'does not clearance duplicate items' do
          upload_first_item
          upload_single_item(single_item)
          expect(page).to have_content "Item id #{single_item.id} already clearanced"
        end

      end

      context 'adding a second item' do

        it 'to same batch' do
          upload_first_item
          fill_in('item_id', with: other_item.id)
          click_button 'Clearance Item!'
          wait_for_ajax
          within('table.active_table') do
            expect(page.all('tr').count).to eq 1
            expect(page.all('tr')[0].all('td')[1]).to have_content "2"
            expect(page).to have_content "Active Batch #{ClearanceBatch.last.id}"
          end
        end

        it 'to new batch' do
          upload_first_item
          upload_single_item_to_batch(other_item.id, 'New Batch')
          check_active_item_count(1,1)
        end

        it 'to different batch' do
          FactoryBot.create(:active_batch)
          FactoryBot.create(:active_batch)

          visit '/'
          check_active_item_count(5,5)

          upload_single_item_to_batch(single_item.id, '1')
          check_active_item_count(6,5)

          upload_single_item_to_batch(other_item.id, '2')
          check_active_item_count(6,6)
        end
      end

    end

    describe "add a new clearance batch", js: true do

      context "total success" do

        it "should allow a user to upload a new clearance batch successfully" do
          items = 5.times.map{ FactoryBot.create(:item) }
          file_name = generate_csv_file(items)
          upload_batch_file(file_name)
          new_batch = ClearanceBatch.first
          expect(page).to have_content("#{items.count} Items clearanced into batch #{new_batch.id}")
          expect(page).not_to have_content("item ids raised errors and were not clearanced")
          within('table.completed_table') do
            expect(page.all('tr').count).to eq 1
          end
        end

      end

      context "partial success" do

        it "should allow a user to upload a new clearance batch partially successfully, and report on errors" do
          valid_items   = 3.times.map{ FactoryBot.create(:item) }
          invalid_items = [[987654], ['no thanks']]
          file_name     = generate_csv_file(valid_items + invalid_items)
          upload_batch_file(file_name)
          new_batch = ClearanceBatch.first
          expect(page).to have_content("#{valid_items.count} Items clearanced into batch #{new_batch.id}")
          expect(page).to have_content("#{invalid_items.count} ids raised errors and were not clearanced")
          within('table.completed_table') do
            expect(page).to have_content('Batch 1')
          end
        end

      end

      context "total failure" do

        it "should allow a user to upload a new clearance batch that totally fails to be clearanced" do
          invalid_items = [[8675309], ['no thanks']]
          file_name     = generate_csv_file(invalid_items)
          upload_batch_file(file_name)
          expect(page).not_to have_content("items clearanced into batch")
          expect(page).to have_content("No new clearance batch was added")
          expect(page).to have_content("#{invalid_items.count} ids raised errors and were not clearanced")
          within('table.completed_table') do
            expect(page).not_to have_content(/ Batch \d+/)
          end
        end
      end
    end

    describe 'Batch State', js: true do
      let!(:active_batch) { FactoryBot.create(:active_batch)}
      let!(:completed_batch) { FactoryBot.create(:clearance_batch_with_items)}

      it "an active batch can be closed" do
        visit('/')
        check_count_all_rows(1,1)
        within('table.active_table') do
          first('.close-btn').click
          wait_for_ajax
        end
        check_count_all_rows(2,0)
      end

      it "a completed batch can be reactivated" do
        visit('/')
        check_count_all_rows(1,1)
        within('table.completed_table') do
          first('.open-btn').click
          wait_for_ajax
        end
        check_count_all_rows(0,2)
      end
    end

    describe 'Help' do
      it 'does not display help on load' do
        visit '/'
        expect(page).to have_selector('#help-container', visible: false)
      end

      it 'clicking help icon displays help' do
        visit '/'
        expect(page).to have_selector('#help-container', visible: false)
        find('.btn-help').click
        expect(page).to have_selector('#help-container', visible: true)
      end

      it 'clicking help icon a second time hides help' do
        visit '/'
        expect(page).to have_selector('#help-container', visible: false)
        find('.btn-help').click
        expect(page).to have_selector('#help-container', visible: true)
        find('.btn-help').click
        expect(page).to have_selector('#help-container', visible: false)
      end
    end

  end

  describe 'SHOW', type: :feature do

    let!(:batch_1) {FactoryBot.create(:clearance_batch_with_items)}
    let!(:batch_2) {FactoryBot.create(:clearance_batch_with_items)}

    context 'PDF' do

      it 'navigates to PDF report' do
        visit '/'
        within('table.completed_table') do
          first('.pdf-btn').click
          expect(current_path).to eq clearance_batch_path(batch_2, format: :pdf)
          expect(page.response_headers).to have_content('application/pdf')
        end
      end

      it "renders correct PDF" do
        visit "/clearance_batches/#{batch_1.id}.pdf"
        expect(page.response_headers).to have_content("clearance_batch_#{batch_1.id}.pdf")
        pdf_to_pdf # CapybaraHelper - parse PDF => page @body
        expect(page.body.count('$')).to eq batch_1.items.count
      end

    end

    context 'CSV' do

      it "navigates to CSV report" do
        visit '/'
        within('table.completed_table') do
          within(first('.batch-row')) do
            find('.csv-btn').click
            expect(current_path).to eq clearance_batch_path(batch_2, format: :csv)
          end
        end
      end

      it 'renders correct CSV' do
        visit '/clearance_batches/1.csv'
        batch_1.items.each do |item|
          expect(page).to have_content(csv_headers(item).join(','))
          expect(page).to have_content(csv_attrs(item).values.join(','))
        end
      end

    end

    context 'HTML' do

      it "navigates to HTML report" do
        visit '/'
        within('table.completed_table') do
          within(first('.batch-row')) do
            click_button('View')
            expect(current_path).to eq clearance_batch_path(batch_2)
          end
        end
      end

      it "renders report" do
        visit '/clearance_batches/1'
        within('table#batch-report') do
          expect(page.all('tr').count).to eq 5
          expect(page).to have_content(batch_1.items.first.price_sold.to_f)
          expect(page.body).to have_content("Clearance Batch Report:")
          expect(page.body).to have_content("Batch ID: #{batch_1.id}")
        end
      end

      it "can export PDF report" do
        visit '/clearance_batches/1'
        within('#report-header') do
          find('.pdf-btn').click
          expect(current_path).to eq clearance_batch_path(batch_1, format: :pdf)
          expect(page.response_headers).to have_content('application/pdf')
        end
      end

      it "can export CSV report" do
        item = Item.find(1)
        visit '/clearance_batches/1'
        within('#report-header') do
          find('.csv-btn').click
          expect(page.body).to have_content(csv_headers(item).join(','))
          expect(page.body).to have_content(csv_attrs(item).values.join(','))
        end
      end

    end
  end

end
