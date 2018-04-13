require 'rails_helper'

describe Item do

  describe "attributes" do
    it { should allow_value('M').for(:size)}
    it { should allow_value('Blue').for(:color)}
    it { should allow_value('sellable').for(:status)}
    it { should allow_value(10).for(:price_sold)}
    it { should allow_value(DateTime.now).for(:sold_at)}
  end

  describe "#perform_clearance!" do

    let(:wholesale_price) { 100 }
    let(:item) { FactoryBot.create(:item, style: FactoryBot.create(:style, wholesale_price: wholesale_price)) }

    before do
      item.clearance!
      item.reload
    end

    it "should mark the item status as clearanced" do
      expect(item.status).to eq("clearanced")
    end

    it "should set the price_sold as 75% of the wholesale_price" do
      expect(item.price_sold).to eq(BigDecimal.new(wholesale_price) * BigDecimal.new("0.75"))
    end
  end
end
