require 'rails_helper'

describe ClearancingService do

  describe "::process_item" do

    context "total success new batch" do
      let(:item) { FactoryBot.create(:item) }
      before(:each) { @clearance_service = ClearancingService.new(item_id: item.id, batch: nil).execute! }

      it "creates a clearance batch" do
        expect(@clearance_service.batch.new_record?).to be false
      end

      it "encounters no errors" do
        expect(@clearance_service.errors.empty?).to be true
      end

      it "adds all the items to the batch" do
        expect(@clearance_service.batch.items.pluck(:id).first).to eq item.id
      end

      it "sets all items to 'clearanced' status" do
        expect(@clearance_service.batch.items.first.status).to eq("clearanced")
      end
    end

    context "total success existing batch" do
      let(:batch) { FactoryBot.create(:clearance_batch) }
      let(:item) { FactoryBot.create(:item) }
      before(:each) { @clearance_service = ClearancingService.new(item_id: item.id, batch: batch).execute! }

      it "encounters no errors" do
        expect(@clearance_service.errors.empty?).to be true
      end

      it "adds all the items to the batch" do
        expect(@clearance_service.batch.items.pluck(:id).first).to eq item.id
      end

      it "sets all items to 'clearanced' status" do
        expect(@clearance_service.batch.items.first.status).to eq("clearanced")
      end
    end

    context "total failure with batch" do
      let!(:item) { FactoryBot.create(:item) }
      let!(:batch) { FactoryBot.create(:clearance_batch) }

      it 'handles invalid input' do
        @clearance_service = ClearancingService.new(item_id: 'A', batch: batch).execute!
        expect(@clearance_service.errors).to include "Item id 0 is not valid"
      end

      it 'handles item not found' do
        @clearance_service = ClearancingService.new(item_id: 1234, batch: batch).execute!
        expect(@clearance_service.errors).to include "Item id 1234 could not be found"
      end

      it 'handles an item already clearanced' do
        existing_batch = FactoryBot.create(:clearance_batch_with_items)
        existing_item = existing_batch.items.first
        @clearance_service = ClearancingService.new(item_id: existing_item.id, batch: existing_batch).execute!
        expect(@clearance_service.errors).to include "Item id #{existing_item.id} already clearanced into Batch #{existing_batch.id}"
      end

      it 'handles an item not sellable' do
        sold_item = FactoryBot.create(:item, status: 'sold')
        @clearance_service = ClearancingService.new(item_id: sold_item.id, batch: batch).execute!
        expect(@clearance_service.errors).to include "Item id #{sold_item.id} could not be clearanced"
      end

    end

    context "total failure without batch" do
      let!(:item) { FactoryBot.create(:item) }

      it 'handles invalid input' do
        @clearance_service = ClearancingService.new(item_id: 'A', batch: nil).execute!
        expect(@clearance_service.errors).to include "Item id 0 is not valid"
      end

      it 'handles item not found' do
        @clearance_service = ClearancingService.new(item_id: 1234, batch: nil).execute!
        expect(@clearance_service.errors).to include "Item id 1234 could not be found"
      end

      it 'handles an item already clearanced' do
        existing_batch = FactoryBot.create(:clearance_batch_with_items)
        existing_item = existing_batch.items.first
        @clearance_service = ClearancingService.new(item_id: existing_item.id, batch: nil).execute!
        expect(@clearance_service.errors).to include "Item id #{existing_item.id} already clearanced into Batch #{existing_batch.id}"
      end

      it 'handles an item not sellable' do
        sold_item = FactoryBot.create(:item, status: 'sold')
        @clearance_service = ClearancingService.new(item_id: sold_item.id, batch: nil).execute!
        expect(@clearance_service.errors).to include "Item id #{sold_item.id} could not be clearanced"
      end

    end
  end

  describe "::process_file" do

    context "total success" do
      let(:items)         { 5.times.map { FactoryBot.create(:item) } }
      let(:file_name)     { generate_csv_file(items) }
      let(:uploaded_file) { Rack::Test::UploadedFile.new(file_name) }

      before do
        @clearance_service = ClearancingService.new(file: uploaded_file).execute!
      end

      it "creates a clearance batch" do
        expect(@clearance_service.batch.new_record?).to be false
      end

      it "encounters no errors" do
        expect(@clearance_service.errors.empty?).to be true
      end

      it "adds all the items to the batch" do
        expect(@clearance_service.batch.items.pluck(:id).sort).to eq(items.map(&:id).sort)
      end

      it "sets all items to 'clearanced' status" do
        expect(@clearance_service.batch.items.pluck(:status).uniq).to eq(["clearanced"])
      end
    end

    context "partial success" do
      let(:valid_items)       { 3.times.map { FactoryBot.create(:item) } }
      let(:unsellable_item)   { FactoryBot.create(:item, status: 'clearanced') }
      let(:non_existent_id)   { 987654 }
      let(:invalid_id)        { 'no thanks' }
      let(:no_id)             { nil }
      let(:float_id)          { 123.45 }
      let(:invalid_items)     {
        [
          [non_existent_id],
          [invalid_id],
          [no_id],
          [float_id],
          [unsellable_item.id],
        ]
      }
      let(:file_name)         { generate_csv_file(valid_items + invalid_items) }
      let(:uploaded_file)     { Rack::Test::UploadedFile.new(file_name) }

      before do
        @clearance_service = ClearancingService.new(file: uploaded_file).execute!
      end

      it "detects all errors generated by invalid items" do
        # Add 1 accounting for error report
        expect(@clearance_service.errors.count).to eq(invalid_items.count + 1)
        [ invalid_id, no_id ].each do |bad_id|
          expect(@clearance_service.errors).to include("Item id #{bad_id.to_i} is not valid")
        end
        expect(@clearance_service.errors).to include("Item id #{non_existent_id} could not be found")
        expect(@clearance_service.errors).to include("Item id #{float_id.to_i} could not be found")
        expect(@clearance_service.errors).to include("Item id #{unsellable_item.id} already clearanced into Batch ")
      end

      it "includes all valid items in the batch" do
        expect(@clearance_service.batch.items.pluck(:id)).to eq(valid_items.map(&:id))
      end
    end

    context "total failure" do
      let(:invalid_items) { [[987654], ['no thanks']] }
      let(:file_name)     { generate_csv_file(invalid_items) }
      let(:uploaded_file) { Rack::Test::UploadedFile.new(file_name) }

      before do
        @clearance_service = ClearancingService.new(file: uploaded_file).execute!
      end

      it "should indicate all items as having errors" do
        # Add 2 accounting for error report
        expect(@clearance_service.errors.count).to eq(invalid_items.count + 2)
      end
      it "should not create a new ClearanceBatch" do
        expect(@clearance_service.batch.new_record?).to be true
      end
    end
  end
end
