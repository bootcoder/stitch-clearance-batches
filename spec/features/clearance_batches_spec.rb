require "rails_helper"

describe "add new monthly clearance_batch" do

  describe "clearance_batches index", type: :feature do

    describe "see previous clearance batches" do

      let!(:clearance_batch_1) { FactoryGirl.create(:clearance_batch) }
      let!(:clearance_batch_2) { FactoryGirl.create(:clearance_batch) }
      let!(:clearance_batch_3) { FactoryGirl.create(:clearance_batch) }

      it "displays a list of all past clearance batches" do
        visit "/"
        expect(page).to have_content("Stitch Fix Clearance Tool")
        expect(page).to have_content("Clearance Batches")
        within('table.clearance_batches') do
          expect(page).to have_content("Clearance Batch #{clearance_batch_1.id}")
          expect(page).to have_content("Clearance Batch #{clearance_batch_2.id}")
          expect(page).to have_content("Clearance Batch #{clearance_batch_3.id}")
        end
      end

    end

    describe "add a new clearance batch" do

      context "total success" do

        it "should allow a user to upload a new clearance batch successfully" do
          items = 5.times.map{ FactoryGirl.create(:item) }
          file_name = generate_csv_file(items)
          visit "/"
          within('table.clearance_batches') do
            expect(page).not_to have_content(/Clearance Batch \d+/)
          end
          attach_file("Select batch file", file_name)
          click_button "upload batch file"
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
          valid_items   = 3.times.map{ FactoryGirl.create(:item) }
          invalid_items = [[987654], ['no thanks']]
          file_name     = generate_csv_file(valid_items + invalid_items)
          visit "/"
          within('table.clearance_batches') do
            expect(page).not_to have_content(/Clearance Batch \d+/)
          end
          attach_file("Select batch file", file_name)
          click_button "upload batch file"
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
          invalid_items = [[987654], ['no thanks']]
          file_name     = generate_csv_file(invalid_items)
          visit "/"
          within('table.clearance_batches') do
            expect(page).not_to have_content(/Clearance Batch \d+/)
          end
          attach_file("Select batch file", file_name)
          click_button "upload batch file"
          expect(page).not_to have_content("items clearanced in batch")
          expect(page).to have_content("No new clearance batch was added")
          expect(page).to have_content("#{invalid_items.count} item ids raised errors and were not clearanced")
          within('table.clearance_batches') do
            expect(page).not_to have_content(/Clearance Batch \d+/)
          end
        end
      end
    end

    describe "PDF report" do
      let!(:batch_1) {FactoryGirl.create(:clearance_batch_with_items)}
      let!(:batch_2) {FactoryGirl.create(:clearance_batch_with_items)}

      it "has a link to generate PDF" do

        visit "/"

        within('table.clearance_batches') do
          btn = page.all('.report-btn')[1]
          # btn = first('.report-btn')
          expect(btn.value).to eq 'PDF'
        end

      end

      it "renders PDF" do

        visit '/'

        within('table.clearance_batches') do
          page.all('.report-btn')[1].click
          # has path
          expect(current_path).to eq clearance_batch_path(batch_1, format: :pdf)
          # is a PDF
          expect(page.response_headers).to have_content('application/pdf')
          # contains correct filename
          expect(page.response_headers).to have_content("clearance_batch_#{batch_1.id}.pdf")

          # PDF Content Setup
          temp_pdf = Tempfile.new('pdf')
          temp_pdf << page.source.force_encoding('UTF-8')
          reader = PDF::Reader.new(temp_pdf)
          pdf_text = reader.pages.map(&:text)
          temp_pdf.close
          page.driver.response.instance_variable_set('@body', pdf_text)

          # contains title
          expect(page.body).to have_content("Clearance Batch #{batch_1.id} Report:")
          # binding.pry
          # contains items
          # will test in the _show since that is what is rendered
        end
      end

    end

  end
end

describe 'show' do

  let!(:batch_1) {FactoryGirl.create(:clearance_batch_with_items)}
  let!(:batch_2) {FactoryGirl.create(:clearance_batch_with_items)}

  it "navigates to the correct show" do
    visit '/'
    within('table.clearance_batches') do

      within(first('.batch-row')) do
        click_button('View')
        expect(current_path).to eq clearance_batch_path(batch_1)
      end
    end
  end

  it "renders report" do

    visit '/clearance_batches/1'

    within('table#batch-report') do
      expect(page).to have_content(batch_1.items.first.price_sold.to_f)
    end

  end

  it "has alternating backgrounds" do

    visit '/clearance_batches/1'

    within('table#batch-report') do
      first_row = first('.report-row')
      second_row = page.all('.report-row')[1]
      expect(first_row[:class].include?('gray-bg')).to be true
      expect(second_row[:class].include?('gray-bg')).to be false
    end

  end
end























