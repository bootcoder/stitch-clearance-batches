require 'rails_helper'

describe ClearanceBatchesController, type: :controller do

  describe 'INDEX' do

    let!(:batch_1) { FactoryBot.create(:clearance_batch_with_items)}
    let!(:batch_2) { FactoryBot.create(:clearance_batch_with_items)}

    before(:each) { get :index }

    it "assigns all batches" do
      expect(assigns(:clearance_batches)).to eq [batch_1, batch_2]
    end

    it "renders the index template with 200" do
      expect(response).to render_template(:index)
      expect(response).to have_http_status(200)
    end

  end

  describe 'SHOW' do

    let!(:batch_1) { FactoryBot.create(:clearance_batch_with_items)}
    let!(:batch_2) { FactoryBot.create(:clearance_batch_with_items)}

    it "assigns the correct batch" do
      get :show, params: { id: batch_1 }
      expect(assigns(:clearance_batch)).to eq batch_1
    end

    it "responds to HTML" do
      get :show, params: { id: batch_1 }
      expect(response).to render_template(:show)
      expect(response).to have_http_status(200)
    end

    it "responds to PDF" do
      get :show, params: { id: batch_1, format: :pdf }
      expect(response.header['Content-Type']).to eq 'application/pdf'
    end

    it "responds to CSV" do
      get :show, params: { id: batch_1, format: :csv }
      expect(response.header['Content-Type']).to include 'text/csv'
    end

  end

  describe "CREATE" do

    let!(:items) { 5.times.map{ FactoryBot.create(:item) } }

    context "batch items" do
      let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/support/spec_csv.csv')) }

      before(:each) { post :create, params: { csv_file: file } }

      it "creates a new batch" do
        expect(ClearanceBatch.count).to eq 1
      end

      it "clearances batch items" do
        expect(Item.where(status: 'clearanced').length).to be 5
      end
    end


    context "single item" do
      it "clearances item without batch given, creates a batch" do
        expect(ClearanceBatch.count).to eq 0
        expect(items.first.status).to eq 'sellable'

        post :create, params: { item_id: items.first }

        expect(Item.find(items.first.id).status).to eq 'clearanced'
        expect(ClearanceBatch.last.items).to eq [items.first]
      end

      it "clearances item with batch given, adds to batch" do
        batch = FactoryBot.create(:clearance_batch_with_items)

        expect(items.first.status).to eq 'sellable'
        expect(ClearanceBatch.count).to eq 1
        expect(batch.items).not_to include items.first

        post :create, params: { item_id: items.first, batch_id: batch }

        expect(Item.first.status).to eq 'clearanced'
        expect(ClearanceBatch.count).to eq 1
        expect(ClearanceBatch.last.items).to include items.first
      end
    end

    context "INVALID INPUT" do
      it ""
    end
  end

end
