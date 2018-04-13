require "rails_helper"

describe "clearance_batch" do

  describe "INDEX", type: :feature do

    describe "see previous clearance batches" do

      let!(:clearance_batch_1) { FactoryBot.create(:clearance_batch) }
      let!(:clearance_batch_2) { FactoryBot.create(:clearance_batch) }
      let!(:clearance_batch_3) { FactoryBot.create(:clearance_batch) }

      it "displays a list of all past clearance batches" do
        visit "/"
        expect(page).to have_content("Clearance Batches")
        within('table.clearance_batches') do
          expect(page).to have_content("Clearance Batch #{clearance_batch_1.id}")
          expect(page).to have_content("Clearance Batch #{clearance_batch_2.id}")
          expect(page).to have_content("Clearance Batch #{clearance_batch_3.id}")
        end
      end

    end

    describe 'displays report links in previous batches' do
      let!(:batch_1) {FactoryBot.create(:clearance_batch_with_items)}

      it "Batch has links to generate reports" do
        visit "/"
        within('table.clearance_batches') do
          within(first('.batch-row')) do
            pdf = find('.pdf-btn')
            csv = find('.csv-btn')
            html = find('.html-btn')
            expect(pdf.value).to eq 'PDF'
            expect(csv.value).to eq 'CSV'
            expect(html.value).to eq 'HTML'
          end
        end
      end
    end

    describe 'add a new clearance item' do
      let!(:single_item) { FactoryBot.create(:item, color: 'gumdrop-glow') }

      context 'total success' do
        it 'should allow a user to clearance a single item successfully' do
          upload_single_item
          expect(ClearanceBatch.last.items).to include single_item
        end
      end

      context 'total failure' do

      end

    end

    describe "add a new clearance batch" do

      context "total success" do

        it "should allow a user to upload a new clearance batch successfully" do
          items = 5.times.map{ FactoryBot.create(:item) }
          file_name = generate_csv_file(items)
          upload_batch_file(file_name)
          new_batch = ClearanceBatch.first
          expect(page).to have_content("#{items.count} items clearanced in batch #{new_batch.id}")
          expect(page).not_to have_content("item ids raised errors and were not clearanced")
          within('table.clearance_batches') do
            expect(page).to have_content(/Clearance Batch \d+/)
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
          expect(page).to have_content("#{valid_items.count} items clearanced in batch #{new_batch.id}")
          expect(page).to have_content("#{invalid_items.count} item ids raised errors and were not clearanced")
          within('table.clearance_batches') do
            expect(page).to have_content(/Clearance Batch \d+/)
          end
        end

      end

      context "total failure" do

        it "should allow a user to upload a new clearance batch that totally fails to be clearanced" do
          invalid_items = [[8675309], ['no thanks']]
          file_name     = generate_csv_file(invalid_items)
          upload_batch_file(file_name)
          expect(page).not_to have_content("items clearanced in batch")
          expect(page).to have_content("No new clearance batch was added")
          expect(page).to have_content("#{invalid_items.count} item ids raised errors and were not clearanced")
          within('table.clearance_batches') do
            expect(page).not_to have_content(/Clearance Batch \d+/)
          end
        end
      end
    end
  end

  describe 'SHOW', type: :feature do

    let!(:batch_1) {FactoryBot.create(:clearance_batch_with_items)}
    let!(:batch_2) {FactoryBot.create(:clearance_batch_with_items)}

    context 'PDF' do

      it 'navigates to PDF report' do
        visit '/'
        within('table.clearance_batches') do
          first('.pdf-btn').click
          expect(current_path).to eq clearance_batch_path(batch_1, format: :pdf)
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
        within('table.clearance_batches') do
          within(first('.batch-row')) do
            find('.csv-btn').click
            expect(current_path).to eq clearance_batch_path(batch_1, format: :csv)
          end
        end
      end

      it 'renders correct CSV' do
        visit '/clearance_batches/1.csv'
        expect(page).to have_content(Item.attribute_names.join(','))
        expect(page).to have_content(batch_1.items.first.attributes.values.join(','))
      end

    end

    context 'HTML' do

      it "navigates to HTML report" do
        visit '/'
        within('table.clearance_batches') do
          within(first('.batch-row')) do
            click_button('HTML')
            expect(current_path).to eq clearance_batch_path(batch_1)
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

      it "rows have alternating backgrounds" do
        visit '/clearance_batches/1'
        within('table#batch-report') do
          first_row = first('.report-row')
          second_row = page.all('.report-row')[1]
          expect(first_row[:class].include?('gray-bg')).to be true
          expect(second_row[:class].include?('gray-bg')).to be false
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
        visit '/clearance_batches/1'
        within('#report-header') do
          find('.csv-btn').click
          expect(page.body).to have_content(Item.attribute_names.join(','))
          expect(page.body).to have_content(batch_1.items.first.attributes.values.join(','))
        end
      end

    end
  end

end
















