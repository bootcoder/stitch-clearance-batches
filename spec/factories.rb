FactoryGirl.define do

  factory :clearance_batch do
    factory :clearance_batch_with_items do
      transient do
        items_count 5
      end
      after(:create) do |clearance_batch, evaluator|
        create_list(:item, evaluator.items_count, clearance_batch: clearance_batch)
      end
    end
  end

  factory :item do
    style
    color "Blue"
    size "M"
    status "sellable"
  end

  factory :style do
    wholesale_price 55
  end
end
