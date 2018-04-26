DISABLE 3rd MONITOR!!!

REPORT DD SORT

Talk about whether to use csv_headers (including helper in controller)
VS hardcoding in view (less DRY but doesn't break principles)

Will need sort helper for items - CB#sort_items_by(attr,flow)
Ask if I should go ahead and add the model spec or if the integration is sufficent.

Ask about not

Update an item before each spec

Other Features

Could add a close batch btn to batch show

JS for auto sort on select





```ruby
#what_the_sort V1

  def what_the_sort(batch, sort)
    case sort
    when 'id-asc'
      return batch.sort_items_by('id')
    when 'id-desc'
      return batch.sort_items_by('id', 'desc')
    when 'size-asc'
      return batch.sort_items_by('size')
    when 'size-desc'
      return batch.sort_items_by('size', 'desc')
    when 'color-asc'
      return batch.sort_items_by('color')
    when 'color-desc'
      return batch.sort_items_by('color', 'desc')
    when 'price-asc'
      return batch.sort_items_by('price_sold')
    when 'price-desc'
      return batch.sort_items_by('price_sold', 'desc')
    when 'style-asc'
      return batch.sort_items_by('style_id')
    when 'style-desc'
      return batch.sort_items_by('style_id', 'desc')
    when 'date-asc'
      return batch.sort_items_by('sold_at')
    when 'date-desc'
      return batch.sort_items_by('sold_at', 'desc')
    else
      return batch.sort_items_by('updated_at', 'desc')
    end
  end

```

```bash
diff --git a/Gemfile.lock b/Gemfile.lock
index 1016286..414425b 100755
--- a/Gemfile.lock
+++ b/Gemfile.lock
@@ -92,7 +92,7 @@ GEM
     erubi (1.7.1)
     eventmachine (1.2.5)
     execjs (2.7.0)
-    extra_print (2.0.0)
+    extra_print (1.1.7)
       awesome_print (~> 1.8, >= 1.8.0)
     factory_bot (4.8.2)
       activesupport (>= 3.0.0)
diff --git a/app/assets/javascripts/main.js b/app/assets/javascripts/main.js
deleted file mode 100644
index 83a7c23..0000000
--- a/app/assets/javascripts/main.js
+++ /dev/null
@@ -1,10 +0,0 @@
-$(document).ready(function () {
-  reportSortListener();
-});
-
-
-var reportSortListener = function () {
-  $('#sort-select').on('change', function () {
-    $('#sort-select-btn').click();
-  });
-};
diff --git a/app/assets/stylesheets/report.scss b/app/assets/stylesheets/report.scss
index 1777b90..14f1067 100644
--- a/app/assets/stylesheets/report.scss
+++ b/app/assets/stylesheets/report.scss
@@ -34,10 +34,6 @@ tr {
   background-color: gray;
 }

-.btn-report {
-  margin-top: 12px;
-}
-
 .table td {
   vertical-align: inherit;
 }
diff --git a/app/controllers/clearance_batches_controller.rb b/app/controllers/clearance_batches_controller.rb
index 6f3ffd1..c9090af 100755
--- a/app/controllers/clearance_batches_controller.rb
+++ b/app/controllers/clearance_batches_controller.rb
@@ -1,8 +1,5 @@
-# NOTE: HTC DEBUGGER REMOVE B4 PRODUCTION
-system 'clear'
-
 class ClearanceBatchesController < ApplicationController
-  include ItemHelper
+

   # NOTE: Split batches into two groups for active and completed
   # Started out with several Ajax views but ultimately decided things were small
@@ -19,41 +16,16 @@ class ClearanceBatchesController < ApplicationController

   def show
     @clearance_batch = ClearanceBatch.includes(:items).find(params[:id])
-    @sort_options = {'id-asc' => { text: 'ID UP',  search_term: 'id', desc: false },
-                     'id-desc' => { text: 'ID DN',  search_term: 'id', desc: true },
-                     'size-asc' => { text: 'Size UP',  search_term: 'size', desc: false },
-                     'size-desc' => { text: 'Size DN',  search_term: 'size', desc: true },
-                     'color-asc' => { text: 'Color UP',  search_term: 'color', desc: false },
-                     'color-desc' => { text: 'Color DN',  search_term: 'color', desc: true },
-                     'price-asc' => { text: 'Price UP',  search_term: 'price_sold', desc: false },
-                     'price-desc' => { text: 'Price DN',  search_term: 'price_sold', desc: true },
-                     'style-asc' => { text: 'Style UP',  search_term: 'style_id', desc: false },
-                     'style-desc' => { text: 'Style DN',  search_term: 'style_id', desc: true },
-                     'date-asc' => { text: 'Date UP',  search_term: 'sold_at', desc: false },
-                     'date-desc' => { text: 'Date DN',  search_term: 'sold_at', desc: true },
-                     'updated-asc' => { text: 'Updated UP',  search_term: 'updated_at', desc: false },
-                     'updated-desc' => { text: 'Updated DN',  search_term: 'updated_at', desc: true }}
-
-    @select_options = []
-
-    @sort_options.keys.map { |e| @select_options << [@sort_options[e][:text], e]}
-
-    if @clearance_batch
-      @items = what_the_sort(@clearance_batch, clearance_params[:sort])
-
-      respond_to do |format|
-        format.html
-        format.csv
-        format.js
-        format.pdf do
-          render pdf: "clearance_batch_#{@clearance_batch.id}",
-                 template: 'clearance_batches/_report.html.erb',
-                 layout: 'pdf.html',
-                 title: "clearance_batch_#{@clearance_batch.id}"
-        end
+
+    respond_to do |format|
+      format.html
+      format.csv
+      format.pdf do
+        render pdf: "clearance_batch_#{@clearance_batch.id}",
+               template: 'clearance_batches/_report.html.erb',
+               layout: 'pdf.html',
+               title: "clearance_batch_#{@clearance_batch.id}"
       end
-    else
-      # Errors and things
     end
   end

@@ -122,12 +94,7 @@ class ClearanceBatchesController < ApplicationController

   # NOTE: Added Strong params because..... That's what you do. :-)
   def clearance_params
-    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch, :sort)
-  end
-
-  def what_the_sort(batch, sort)
-    sort ||= 'updated-desc'
-    batch.sort_items_by(@sort_options[sort][:search_term], @sort_options[sort][:desc])
+    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch)
   end

 end
diff --git a/app/models/clearance_batch.rb b/app/models/clearance_batch.rb
index 77579ba..262d151 100755
--- a/app/models/clearance_batch.rb
+++ b/app/models/clearance_batch.rb
@@ -4,14 +4,10 @@ class ClearanceBatch < ActiveRecord::Base
     self.active ? "Active Batch #{self.id}" : "Batch #{self.id}"
   end

+
   has_many :items

   scope :active, -> { includes(:items).where(active: true).order(updated_at: :desc) }
   scope :completed, -> { includes(:items).where(active: false).order(updated_at: :desc) }

-  def sort_items_by(attr, desc = false)
-    return unless Item.column_names.include?(attr)
-    desc ? items.order("#{attr} desc") : items.order("#{attr}")
-  end
-
 end
diff --git a/app/views/clearance_batches/_report.html.erb b/app/views/clearance_batches/_report.html.erb
index f30a7ef..938a199 100644
--- a/app/views/clearance_batches/_report.html.erb
+++ b/app/views/clearance_batches/_report.html.erb
@@ -11,7 +11,7 @@
         <th scope='col' >Status</th>
       </thead>
       <tbody>
-        <% @items.each_with_index do |item, idx| %>
+        <% @clearance_batch.items.each_with_index do |item, idx| %>
           <tr class="report-row">
             <th scope='row' ><%= item.id %></th>
             <td><%= item.size %></td>
diff --git a/app/views/clearance_batches/show.html.erb b/app/views/clearance_batches/show.html.erb
index 52d15c0..d23bc77 100644
--- a/app/views/clearance_batches/show.html.erb
+++ b/app/views/clearance_batches/show.html.erb
@@ -4,25 +4,13 @@
       <h2>Clearance Batch Report:</h2>
       <h4>Batch ID: <%= @clearance_batch.id %> &nbsp; &nbsp; Total Items: <%= @clearance_batch.items.count %></h4>
     </div>
-    <div class='col-md-3 text-center'>
+    <div class='col-md-6 text-center'>
       <h4>Export Options</h4>
       <div class='btn-group btn-group-lg' role='group'>
-        <%= button_to "PDF", clearance_batch_path(@clearance_batch, format: :pdf), method: :get, class: 'completed-btn pdf-btn btn btn-primary btn-report'  %>
-        <%= button_to "CSV", clearance_batch_path(@clearance_batch, format: :csv), method: :get, class: 'completed-btn csv-btn btn btn-primary btn-report'  %>
+        <%= button_to "PDF", clearance_batch_path(@clearance_batch, format: :pdf), method: :get, class: 'completed-btn pdf-btn btn btn-primary'  %>
+        <%= button_to "CSV", clearance_batch_path(@clearance_batch, format: :csv), method: :get, class: 'completed-btn csv-btn btn btn-primary'  %>
       </div>
     </div>
-    <div class='col-md-3 text-center'>
-      <h4>Sort By</h4>
-      <div class='btn-group btn-group-lg' role='group'>
-        <%= form_with url: clearance_batch_path(@clearance_batch), method: :get, remote: true, class: 'form-inline' do |f| %>
-
-            <%= f.select :sort, options_for_select(@select_options), {}, {class: 'form-control', id: 'sort-select'} %>
-            <%= f.button '>', id: 'sort-select-btn', class: 'btn btn-primary' %>
-
-        <% end %>
-      </div>
-    </div>
-
   </div>
 </div>

diff --git a/app/views/clearance_batches/show.js.erb b/app/views/clearance_batches/show.js.erb
deleted file mode 100644
index 68a3606..0000000
--- a/app/views/clearance_batches/show.js.erb
+++ /dev/null
@@ -1 +0,0 @@
-$('#batch-report').parents('.container').replaceWith("<%= j render partial: 'report' %>")
diff --git a/spec/features/clearance_batches_spec.rb b/spec/features/clearance_batches_spec.rb
index ca7cb08..e2c792f 100755
--- a/spec/features/clearance_batches_spec.rb
+++ b/spec/features/clearance_batches_spec.rb
@@ -307,79 +307,6 @@ describe "clearance_batch" do
       end

     end
-
-    context "SORT", js: true do
-
-      let!(:updated_item) {batch_1.items.first.update_attributes(color: 'Midnight Blue', size: 'xs', price_sold: 999)}
-
-      it "defaults to updated_at descending" do
-        batch_1.items.first.update_attributes(color: 'Midnight Blue', size: 'xs', price_sold: 999)
-        item = batch_1.sort_items_by('updated_at', 'desc').first
-        visit '/clearance_batches/1'
-        check_first_tr_item(item)
-      end
-
-      it "sorts by ID ascending" do
-        item = batch_1.sort_items_by('id').first
-        report_sort_by(1).check_first_tr_item(item)
-      end
-
-      it "sorts by ID descending" do
-        item = batch_1.sort_items_by('id', 'desc').first
-        report_sort_by(2).check_first_tr_item(item)
-      end
-
-      it "sorts by Size ascending" do
-        item = batch_1.sort_items_by('size').first
-        report_sort_by(3).check_first_tr_item(item)
-      end
-
-      it "sorts by Size descending" do
-        item = batch_1.sort_items_by('size', 'desc').first
-        report_sort_by(4).check_first_tr_item(item)
-      end
-
-      it "sorts by Color ascending" do
-        item = batch_1.sort_items_by('color').first
-        report_sort_by(5).check_first_tr_item(item)
-      end
-
-      it "sorts by Color descending" do
-        item = batch_1.sort_items_by('color', 'desc').first
-        report_sort_by(6).check_first_tr_item(item)
-      end
-
-      it "sorts by Price ascending" do
-        item = batch_1.sort_items_by('price_sold').first
-        report_sort_by(7).check_first_tr_item(item)
-      end
-
-      it "sorts by Price descending" do
-        item = batch_1.sort_items_by('price_sold', 'desc').first
-        report_sort_by(8).check_first_tr_item(item)
-      end
-
-      it "sorts by Style ascending" do
-        item = batch_1.sort_items_by('style_id').first
-        report_sort_by(9).check_first_tr_item(item)
-      end
-
-      it "sorts by Style descending" do
-        item = batch_1.sort_items_by('style_id', 'desc').first
-        report_sort_by(10).check_first_tr_item(item)
-      end
-
-      it "sorts by Date ascending" do
-        item = batch_1.sort_items_by('sold_at').first
-        report_sort_by(11).check_first_tr_item(item)
-      end
-      it "sorts by Date descending" do
-        item = batch_1.sort_items_by('sold_at', 'desc').first
-        report_sort_by(12).check_first_tr_item(item)
-      end
-
-    end
-
   end

 end
diff --git a/spec/support/capybara_helper.rb b/spec/support/capybara_helper.rb
index 651403e..d471c3f 100644
--- a/spec/support/capybara_helper.rb
+++ b/spec/support/capybara_helper.rb
@@ -23,24 +23,6 @@ module CapybaraHelper
     self
   end

-  def check_first_tr_item(item)
-    within('#batch-report tbody') do
-      expect(page.all('tr').count).to eq 5
-      expect(page.first('tr').first('th')).to have_content item.id
-      expect(page.first('tr').first('td')).to have_content item.size
-    end
-  end
-
-  def report_sort_by(option_idx)
-    visit '/clearance_batches/1'
-    within('#report-header') do
-      find('#sort-select').find(:xpath, "option[#{option_idx}]").select_option
-      find('#sort-select-btn').click
-      wait_for_ajax
-    end
-    self
-  end
-
   def upload_batch_file(file_name)
     visit "/"
     within('table.completed_table') do
@@ -74,7 +56,6 @@ module CapybaraHelper
     within('table.completed_table') do
       expect(page).not_to have_content(/Clearance Batch \d+/)
       expect(page).not_to have_content(/Active Batch \d+/)
-      self
     end

     fill_in('item_id', with: item.id)

```
