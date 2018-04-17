require 'rails_helper'

describe ClearanceBatchesController, type: :controller do

  describe 'INDEX' do

    let!(:batch_1) { FactoryBot.create(:clearance_batch_with_items)}
    let!(:batch_2) { FactoryBot.create(:clearance_batch_with_items)}
    let!(:in_progress_batch) { FactoryBot.create(:in_progress_batch)}

    before(:each) { get :index }

    it "assigns all batches" do
      expect(assigns(:clearance_batches)).to eq [batch_1, batch_2]
      expect(assigns(:in_progress_batches)).to eq [in_progress_batch]
    end

    it "renders the index template with 200" do
      expect(response).to render_template(:index)
      expect(response).to have_http_status(200)
    end

  end

  describe 'SHOW' do

    let!(:batch_1) { FactoryBot.create(:clearance_batch_with_items)}

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

  describe "UPDATE" do
    let!(:batch_1) {FactoryBot.create(:in_progress_batch)}
    it "closes a batch" do
      put :update, params: { id: batch_1 }
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(action: :index)
    end

    it "fails to update a previously closed batch" do

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
      it "creates a batch, clearances item" do
        expect(ClearanceBatch.count).to eq 0
        expect(items.first.status).to eq 'sellable'

        post :create, params: { item_id: items.first, batch_id: 'new' }
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

    # Already coving this pretty well in features. May come back...
    # context "INVALID INPUT" do
    #   it "" do

    #   end
    # end
  end

end
