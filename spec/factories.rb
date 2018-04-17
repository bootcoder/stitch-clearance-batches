FactoryBot.define do

  factory :clearance_batch do
    active false
    factory :clearance_batch_with_items do
      transient do
        items_count 5
      end
      after(:create) do |clearance_batch, evaluator|
        create_list(:clearance_item, evaluator.items_count, clearance_batch: clearance_batch)
      end
      factory :active_batch do
        active true
      end
    end
  end

  factory :item do
    style
    color "Blue"
    size "M"
    status "sellable"
    factory :clearance_item do
      after(:create) do |obj|
        obj.clearance!
      end
    end
  end

  factory :style do
    wholesale_price 55
  end
end
