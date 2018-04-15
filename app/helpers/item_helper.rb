module ItemHelper

  def csv_headers(item)
    csv_attrs(item).keys
  end

  def csv_attrs(item)
    {'id' => item.id,
     'size' => item.size,
     'color' => item.color,
     'price_sold' => number_to_currency(item.price_sold),
     'style' => item.style.name,
     'date_sold' => l(item.sold_at, format: :short),
     'status' => item.status}
  end

end
