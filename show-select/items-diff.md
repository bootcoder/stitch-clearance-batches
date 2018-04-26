```bash
diff --git a/Gemfile.lock b/Gemfile.lock
index 414425b..1016286 100755
--- a/Gemfile.lock
+++ b/Gemfile.lock
@@ -92,7 +92,7 @@ GEM
     erubi (1.7.1)
     eventmachine (1.2.5)
     execjs (2.7.0)
-    extra_print (1.1.7)
+    extra_print (2.0.0)
       awesome_print (~> 1.8, >= 1.8.0)
     factory_bot (4.8.2)
       activesupport (>= 3.0.0)
diff --git a/app/assets/javascripts/main.js b/app/assets/javascripts/main.js
new file mode 100644
index 0000000..83a7c23
--- /dev/null
+++ b/app/assets/javascripts/main.js
@@ -0,0 +1,10 @@
+$(document).ready(function () {
+  reportSortListener();
+});
+
+
+var reportSortListener = function () {
+  $('#sort-select').on('change', function () {
+    $('#sort-select-btn').click();
+  });
+};
diff --git a/app/assets/stylesheets/report.scss b/app/assets/stylesheets/report.scss
index 14f1067..1777b90 100644
--- a/app/assets/stylesheets/report.scss
+++ b/app/assets/stylesheets/report.scss
@@ -34,6 +34,10 @@ tr {
   background-color: gray;
 }

+.btn-report {
+  margin-top: 12px;
+}
+
 .table td {
   vertical-align: inherit;
 }
diff --git a/app/controllers/clearance_batches_controller.rb b/app/controllers/clearance_batches_controller.rb
index c9090af..6f3ffd1 100755
--- a/app/controllers/clearance_batches_controller.rb
+++ b/app/controllers/clearance_batches_controller.rb
@@ -1,5 +1,8 @@
-class ClearanceBatchesController < ApplicationController
+# NOTE: HTC DEBUGGER REMOVE B4 PRODUCTION
+system 'clear'

+class ClearanceBatchesController < ApplicationController
+  include ItemHelper

   # NOTE: Split batches into two groups for active and completed
   # Started out with several Ajax views but ultimately decided things were small
@@ -16,16 +19,41 @@ class ClearanceBatchesController < ApplicationController

   def show
     @clearance_batch = ClearanceBatch.includes(:items).find(params[:id])
-
-    respond_to do |format|
-      format.html
-      format.csv
-      format.pdf do
-        render pdf: "clearance_batch_#{@clearance_batch.id}",
-               template: 'clearance_batches/_report.html.erb',
-               layout: 'pdf.html',
-               title: "clearance_batch_#{@clearance_batch.id}"
+    @sort_options = {'id-asc' => { text: 'ID UP',  search_term: 'id', desc: false },
+                     'id-desc' => { text: 'ID DN',  search_term: 'id', desc: true },
+                     'size-asc' => { text: 'Size UP',  search_term: 'size', desc: false },
+                     'size-desc' => { text: 'Size DN',  search_term: 'size', desc: true },
+                     'color-asc' => { text: 'Color UP',  search_term: 'color', desc: false },
+                     'color-desc' => { text: 'Color DN',  search_term: 'color', desc: true },
+                     'price-asc' => { text: 'Price UP',  search_term: 'price_sold', desc: false },
+                     'price-desc' => { text: 'Price DN',  search_term: 'price_sold', desc: true },
+                     'style-asc' => { text: 'Style UP',  search_term: 'style_id', desc: false },
+                     'style-desc' => { text: 'Style DN',  search_term: 'style_id', desc: true },
+                     'date-asc' => { text: 'Date UP',  search_term: 'sold_at', desc: false },
+                     'date-desc' => { text: 'Date DN',  search_term: 'sold_at', desc: true },
+                     'updated-asc' => { text: 'Updated UP',  search_term: 'updated_at', desc: false },
+                     'updated-desc' => { text: 'Updated DN',  search_term: 'updated_at', desc: true }}
+
+    @select_options = []
+
+    @sort_options.keys.map { |e| @select_options << [@sort_options[e][:text], e]}
+
+    if @clearance_batch
+      @items = what_the_sort(@clearance_batch, clearance_params[:sort])
+
+      respond_to do |format|
+        format.html
+        format.csv
+        format.js
+        format.pdf do
+          render pdf: "clearance_batch_#{@clearance_batch.id}",
+                 template: 'clearance_batches/_report.html.erb',
+                 layout: 'pdf.html',
+                 title: "clearance_batch_#{@clearance_batch.id}"
+        end
       end
+    else
+      # Errors and things
     end
   end

@@ -94,7 +122,12 @@ class ClearanceBatchesController < ApplicationController

   # NOTE: Added Strong params because..... That's what you do. :-)
   def clearance_params
-    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch)
+    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch, :sort)
+  end
+
+  def what_the_sort(batch, sort)
+    sort ||= 'updated-desc'
+    batch.sort_items_by(@sort_options[sort][:search_term], @sort_options[sort][:desc])
   end

 end
diff --git a/app/models/clearance_batch.rb b/app/models/clearance_batch.rb
index 262d151..77579ba 100755
--- a/app/models/clearance_batch.rb
+++ b/app/models/clearance_batch.rb
@@ -4,10 +4,14 @@ class ClearanceBatch < ActiveRecord::Base
     self.active ? "Active Batch #{self.id}" : "Batch #{self.id}"
   end

-
   has_many :items

   scope :active, -> { includes(:items).where(active: true).order(updated_at: :desc) }
   scope :completed, -> { includes(:items).where(active: false).order(updated_at: :desc) }

+  def sort_items_by(attr, desc = false)
+    return unless Item.column_names.include?(attr)
+    desc ? items.order("#{attr} desc") : items.order("#{attr}")
+  end
+
 end
diff --git a/app/views/clearance_batches/_report.html.erb b/app/views/clearance_batches/_report.html.erb
index 938a199..f30a7ef 100644
--- a/app/views/clearance_batches/_report.html.erb
+++ b/app/views/clearance_batches/_report.html.erb
@@ -11,7 +11,7 @@
         <th scope='col' >Status</th>
       </thead>
       <tbody>
-        <% @clearance_batch.items.each_with_index do |item, idx| %>
+        <% @items.each_with_index do |item, idx| %>
           <tr class="report-row">
             <th scope='row' ><%= item.id %></th>
             <td><%= item.size %></td>
diff --git a/app/views/clearance_batches/show.html.erb b/app/views/clearance_batches/show.html.erb
index d23bc77..52d15c0 100644
--- a/app/views/clearance_batches/show.html.erb
+++ b/app/views/clearance_batches/show.html.erb
@@ -4,13 +4,25 @@
       <h2>Clearance Batch Report:</h2>
       <h4>Batch ID: <%= @clearance_batch.id %> &nbsp; &nbsp; Total Items: <%= @clearance_batch.items.count %></h4>
     </div>
-    <div class='col-md-6 text-center'>
+    <div class='col-md-3 text-center'>
       <h4>Export Options</h4>
       <div class='btn-group btn-group-lg' role='group'>
-        <%= button_to "PDF", clearance_batch_path(@clearance_batch, format: :pdf), method: :get, class: 'completed-btn pdf-btn btn btn-primary'  %>
-        <%= button_to "CSV", clearance_batch_path(@clearance_batch, format: :csv), method: :get, class: 'completed-btn csv-btn btn btn-primary'  %>
+        <%= button_to "PDF", clearance_batch_path(@clearance_batch, format: :pdf), method: :get, class: 'completed-btn pdf-btn btn btn-primary btn-report'  %>
+        <%= button_to "CSV", clearance_batch_path(@clearance_batch, format: :csv), method: :get, class: 'completed-btn csv-btn btn btn-primary btn-report'  %>
       </div>
     </div>
+    <div class='col-md-3 text-center'>
+      <h4>Sort By</h4>
+      <div class='btn-group btn-group-lg' role='group'>
+        <%= form_with url: clearance_batch_path(@clearance_batch), method: :get, remote: true, class: 'form-inline' do |f| %>
+
+            <%= f.select :sort, options_for_select(@select_options), {}, {class: 'form-control', id: 'sort-select'} %>
+            <%= f.button '>', id: 'sort-select-btn', class: 'btn btn-primary' %>
+
+        <% end %>
+      </div>
+    </div>
+
   </div>
 </div>

diff --git a/app/views/clearance_batches/show.js.erb b/app/views/clearance_batches/show.js.erb
new file mode 100644
index 0000000..68a3606
--- /dev/null
+++ b/app/views/clearance_batches/show.js.erb
@@ -0,0 +1 @@
+$('#batch-report').parents('.container').replaceWith("<%= j render partial: 'report' %>")
diff --git a/spec/features/clearance_batches_spec.rb b/spec/features/clearance_batches_spec.rb
index e2c792f..ca7cb08 100755
--- a/spec/features/clearance_batches_spec.rb
+++ b/spec/features/clearance_batches_spec.rb
@@ -307,6 +307,79 @@ describe "clearance_batch" do
       end

     end
+
+    context "SORT", js: true do
+
+      let!(:updated_item) {batch_1.items.first.update_attributes(color: 'Midnight Blue', size: 'xs', price_sold: 999)}
+
+      it "defaults to updated_at descending" do
+        batch_1.items.first.update_attributes(color: 'Midnight Blue', size: 'xs', price_sold: 999)
+        item = batch_1.sort_items_by('updated_at', 'desc').first
+        visit '/clearance_batches/1'
+        check_first_tr_item(item)
+      end
+
+      it "sorts by ID ascending" do
+        item = batch_1.sort_items_by('id').first
+        report_sort_by(1).check_first_tr_item(item)
+      end
+
+      it "sorts by ID descending" do
+        item = batch_1.sort_items_by('id', 'desc').first
+        report_sort_by(2).check_first_tr_item(item)
+      end
+
+      it "sorts by Size ascending" do
+        item = batch_1.sort_items_by('size').first
+        report_sort_by(3).check_first_tr_item(item)
+      end
+
+      it "sorts by Size descending" do
+        item = batch_1.sort_items_by('size', 'desc').first
+        report_sort_by(4).check_first_tr_item(item)
+      end
+
+      it "sorts by Color ascending" do
+        item = batch_1.sort_items_by('color').first
+        report_sort_by(5).check_first_tr_item(item)
+      end
+
+      it "sorts by Color descending" do
+        item = batch_1.sort_items_by('color', 'desc').first
+        report_sort_by(6).check_first_tr_item(item)
+      end
+
+      it "sorts by Price ascending" do
+        item = batch_1.sort_items_by('price_sold').first
+        report_sort_by(7).check_first_tr_item(item)
+      end
+
+      it "sorts by Price descending" do
+        item = batch_1.sort_items_by('price_sold', 'desc').first
+        report_sort_by(8).check_first_tr_item(item)
+      end
+
+      it "sorts by Style ascending" do
+        item = batch_1.sort_items_by('style_id').first
+        report_sort_by(9).check_first_tr_item(item)
+      end
+
+      it "sorts by Style descending" do
+        item = batch_1.sort_items_by('style_id', 'desc').first
+        report_sort_by(10).check_first_tr_item(item)
+      end
+
+      it "sorts by Date ascending" do
+        item = batch_1.sort_items_by('sold_at').first
+        report_sort_by(11).check_first_tr_item(item)
+      end
+      it "sorts by Date descending" do
+        item = batch_1.sort_items_by('sold_at', 'desc').first
+        report_sort_by(12).check_first_tr_item(item)
+      end
+
+    end
+
   end

 end
diff --git a/spec/support/capybara_helper.rb b/spec/support/capybara_helper.rb
index d471c3f..651403e 100644
--- a/spec/support/capybara_helper.rb
+++ b/spec/support/capybara_helper.rb
@@ -23,6 +23,24 @@ module CapybaraHelper
     self
   end

+  def check_first_tr_item(item)
+    within('#batch-report tbody') do
+      expect(page.all('tr').count).to eq 5
+      expect(page.first('tr').first('th')).to have_content item.id
+      expect(page.first('tr').first('td')).to have_content item.size
+    end
+  end
+
+  def report_sort_by(option_idx)
+    visit '/clearance_batches/1'
+    within('#report-header') do
+      find('#sort-select').find(:xpath, "option[#{option_idx}]").select_option
+      find('#sort-select-btn').click
+      wait_for_ajax
+    end
+    self
+  end
+
   def upload_batch_file(file_name)
     visit "/"
     within('table.completed_table') do
@@ -56,6 +74,7 @@ module CapybaraHelper
     within('table.completed_table') do
       expect(page).not_to have_content(/Clearance Batch \d+/)
       expect(page).not_to have_content(/Active Batch \d+/)
+      self
     end

     fill_in('item_id', with: item.id)

```
