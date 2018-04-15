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

    context "closes a batch and flashes success" do
      let!(:batch) {FactoryBot.create(:in_progress_batch)}
      before(:each) { put :update, params: { id: batch, close_batch: '' } }

      it { should set_flash[:notice].to include "Clearance Batch #{batch.id} successfully closed" }

      it 'renders correctly' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(action: :index)
      end

      it "closes the batch" do
        expect(ClearanceBatch.find(batch.id).in_progress).to eq false
      end
    end

    context "does not update a previously closed batch" do
      let!(:closed_batch) { FactoryBot.create(:clearance_batch_with_items)}
      before(:each) { put :update, params: { id: closed_batch, close_batch: '' } }
      it { should set_flash[:alert].to include "Batch id #{closed_batch.id} is already closed" }
    end

    context "fails to update without close_batch param" do
      let!(:batch) { FactoryBot.create(:in_progress_batch)}
      before(:each) { put :update, params: { id: batch} }
      it { should set_flash[:alert].to include "Failed to update batch #{batch.id}, refresh and try again." }
    end

    context "handles INVALID INPUT correctly" do
      before(:each) { put :update, params: { id: 'fluzinsinks', close_batch: '' } }
      it { should set_flash[:alert].to include "Could not find batch id fluzinsinks" }
    end

    context "handles batch not found correctly" do
      before(:each) { put :update, params: { id: 720, close_batch: '' } }
      it { should set_flash[:alert].to include "Could not find batch id 720" }
    end

  end

  describe "CREATE" do

    let!(:items) { 5.times.map{ FactoryBot.create(:item) } }

    context "batch items" do
      let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/support/spec_csv.csv')) }

      before(:each) { post :create, params: { csv_file: file } }

      it { should set_flash[:notice] }
      it { should set_flash[:alert] }
      it { should redirect_to action: :index}

      it "creates a new batch" do
        expect(ClearanceBatch.count).to eq 1
      end

      it "clearances batch items" do
        expect(Item.where(status: 'clearanced').length).to be 5
      end
    end

    context "single item" do
      it "creates a batch when new batch given, clearances item" do
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

    context 'params' do
      it { should permit(:item_id, :batch_id, :csv_file, :close_batch).for(:create) }
    end

    context "unmet param dependency alerts user" do
      before(:each) { post :create, params: { item_id: 6081279 } }
      it { should set_flash[:alert].to include "You must enter an Item id or CSV file to clearance items" }
    end

    context "invalid ID" do
      before(:each) { post :create, params: { item_id: 6081279, batch_id: '' } }
      it { should set_flash[:alert].to include "Item id 6081279 could not be found" }

      it 'should not alter Item count' do
        expect(Item.count).to eq 5
      end

      it 'should not alter ClearanceBatch count' do
        expect(ClearanceBatch.count).to eq 0
      end
    end

    context 'invalid batch ID' do
      before(:each) { post :create, params: { item_id: 1, batch_id: 978 } }
      it { should set_flash[:notice].to include "Item 1 Clearanced Successfully!" }
      it "creates a new batch" do
        expect(ClearanceBatch.count).to eq 1
      end
      it "clearances item" do
        expect(Item.find(1).status).to eq 'clearanced'
      end
    end

  end

end
