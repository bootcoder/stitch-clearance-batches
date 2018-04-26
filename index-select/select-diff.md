```bash
diff --git a/Gemfile b/Gemfile
index 6499c44..8a02d54 100755
--- a/Gemfile
+++ b/Gemfile
@@ -11,6 +11,7 @@ gem "bootstrap"

 gem 'wicked_pdf'
 gem 'wkhtmltopdf-binary'
+gem 'font-awesome-rails'

 group :test do
   gem "rspec-rails"
diff --git a/Gemfile.lock b/Gemfile.lock
index 414425b..d990347 100755
--- a/Gemfile.lock
+++ b/Gemfile.lock
@@ -100,6 +100,8 @@ GEM
       factory_bot (~> 4.8.2)
       railties (>= 3.0.0)
     ffi (1.9.23)
+    font-awesome-rails (4.7.0.4)
+      railties (>= 3.2, < 6.0)
     formatador (0.2.5)
     globalid (0.4.1)
       activesupport (>= 4.2.0)
@@ -294,6 +296,7 @@ DEPENDENCIES
   database_cleaner
   extra_print
   factory_bot_rails
+  font-awesome-rails
   guard
   guard-livereload
   guard-rspec
diff --git a/app/assets/javascripts/main.js b/app/assets/javascripts/main.js
new file mode 100644
index 0000000..cbdbad6
--- /dev/null
+++ b/app/assets/javascripts/main.js
@@ -0,0 +1,9 @@
+$(document).ready(function () {
+  sortListener();
+});
+
+var sortListener = function () {
+  $('body').on('change', '.sort-select', function () {
+    $(this).parent().find('button').click();
+  });
+};
diff --git a/app/assets/stylesheets/application.scss b/app/assets/stylesheets/application.scss
index bd4fc88..72944d6 100755
--- a/app/assets/stylesheets/application.scss
+++ b/app/assets/stylesheets/application.scss
@@ -1,11 +1,12 @@
 @import "bootstrap";
+@import "font-awesome";
 @import "index";
 @import "report";

 // NOTE: The first line of CSS I write in any app. Such a lifesaver.
 // Usually would remove before production but leaving for you.

-// * {
-//   outline: 1px solid red;
-// }
+* {
+  outline: 1px solid red;
+}

diff --git a/app/assets/stylesheets/index.scss b/app/assets/stylesheets/index.scss
index 4682e52..9733814 100644
--- a/app/assets/stylesheets/index.scss
+++ b/app/assets/stylesheets/index.scss
@@ -95,3 +95,11 @@ h1 a:hover {
   max-height: 30px;
   max-width: 30px;
 }
+
+.sort-select {
+  margin: 0;
+}
+
+.sort-form *{
+  margin: 0 1%;
+}
diff --git a/app/controllers/clearance_batches_controller.rb b/app/controllers/clearance_batches_controller.rb
index c9090af..6b603d9 100755
--- a/app/controllers/clearance_batches_controller.rb
+++ b/app/controllers/clearance_batches_controller.rb
@@ -1,12 +1,14 @@
 class ClearanceBatchesController < ApplicationController

-
   # NOTE: Split batches into two groups for active and completed
   # Started out with several Ajax views but ultimately decided things were small
   # enough to simply re-render index asynchronously
   def index
-    @active_batches = ClearanceBatch.active
-    @completed_batches  = ClearanceBatch.completed
+    session[:active_sort] = clearance_params[:active_order_param] || 'date-desc'
+    session[:completed_sort] = clearance_params[:completed_order_param] || 'date-desc'
+    @last_active = ClearanceBatch.active.order(updated_at: :desc).last
+    @active_batches = what_the_sort(ClearanceBatch.active, session[:active_sort])
+    @completed_batches  = what_the_sort(ClearanceBatch.completed, session[:completed_sort])

     respond_to do |format|
       format.html
@@ -94,7 +96,24 @@ class ClearanceBatchesController < ApplicationController

   # NOTE: Added Strong params because..... That's what you do. :-)
   def clearance_params
-    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch)
+    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch, :active_order_param, :completed_order_param)
+  end
+
+  def what_the_sort(batch, order_param)
+    case order_param
+    when 'items-asc'
+      return batch.sort_by { |b| b.items.count }
+    when 'items-desc'
+      return batch.sort_by { |b| b.items.count }.reverse
+    when 'name-asc'
+      return batch.order(:id)
+    when 'name-desc'
+      return batch.order(id: :desc)
+    when 'date-asc'
+      return batch.order(:updated_at)
+    else
+      return batch.order(updated_at: :desc)
+    end
   end

 end
diff --git a/app/models/clearance_batch.rb b/app/models/clearance_batch.rb
index 262d151..e5c4212 100755
--- a/app/models/clearance_batch.rb
+++ b/app/models/clearance_batch.rb
@@ -7,7 +7,7 @@ class ClearanceBatch < ActiveRecord::Base

   has_many :items

-  scope :active, -> { includes(:items).where(active: true).order(updated_at: :desc) }
-  scope :completed, -> { includes(:items).where(active: false).order(updated_at: :desc) }
+  scope :active, -> { includes(:items).where(active: true) }
+  scope :completed, -> { includes(:items).where(active: false) }

 end
diff --git a/app/views/clearance_batches/_index_form.html.erb b/app/views/clearance_batches/_index_form.html.erb
index 24ef078..a5427db 100644
--- a/app/views/clearance_batches/_index_form.html.erb
+++ b/app/views/clearance_batches/_index_form.html.erb
@@ -17,7 +17,7 @@
       <div class='form-group col-md-4'>
         <%= f.text_field 'item_id', id: 'item_id_input', class: 'form-control', placeholder: 'Single Item ID', autofocus: true, autocomplete: 'off' %>
         <% if @active_batches.any? %>
-          <%= f.select 'batch_id', options_from_collection_for_select(@active_batches, :id, :title, @active_batches.first.id.to_s), {include_blank: 'New Batch'}, {id: 'batch_select', class: 'form-control'} %>
+          <%= f.select 'batch_id', options_from_collection_for_select(@active_batches, :id, :title, @last_active.id), {include_blank: 'New Batch'}, {id: 'batch_select', class: 'form-control'} %>
         <% else %>
           <%= f.select 'batch_id', ['New Batch'], {}, {class: 'form-control'} %>
         <% end %>
diff --git a/app/views/clearance_batches/_table.html.erb b/app/views/clearance_batches/_table.html.erb
index 85cd94a..2d31abd 100644
--- a/app/views/clearance_batches/_table.html.erb
+++ b/app/views/clearance_batches/_table.html.erb
@@ -2,13 +2,21 @@
 <!-- was a good idea from a simplicity standpoint -->
 <!-- I'm not pleased with readability as a result.. -->
 <!-- Also Yes I agree, one should not ordinarily leave a comment in HTML -->
-
-<% if table_state == 'completed' %>
-  <h3 class='table-title text-success'>Completed Batches</h3>
-<% else %>
-  <h3 class='table-title text-danger'>Active Batches</h3>
-<% end %>
-
+<div class='row'>
+  <% if table_state == 'completed' %>
+    <h4 class='col-md-6 text-success'>Completed Batches</h4>
+  <% else %>
+    <h4 class='col-md-6 text-danger'>Active Batches</h4>
+  <% end %>
+  <%= form_with url: clearance_batches_path, method: :get, class: 'form-inline sort-form col-md-6' do |f| %>
+      <% order_param = table_state == 'completed' ? session[:completed_sort] : session[:active_sort] %>
+      <%= f.label 'Sort By:' %>
+      <%= f.select "#{table_state}_order_param", options_for_select([['Date UP', 'date-asc'], ['Date DOWN', 'date-desc'], ['Name Up', 'name-asc'], ['Name Down', 'name-desc'], ['Items UP', 'items-asc'], ['Items DOWN', 'items-desc']], order_param), {}, {class: 'form-control sort-select', id: "#{table_state}-sort-select"} %>
+      <div class='button-group'>
+        <%= f.button fa_icon('angle-double-right x2'), class: 'btn btn-info sort-btn', id: "#{table_state}-sort-btn" %>
+      </div>
+  <% end %>
+</div>
 <div class='table-container'>
   <table class="table table-responsive table-striped <%= table_state %>_table">
     <tbody class='table-body'>
@@ -18,11 +26,7 @@
           <td><%= pluralize(batch.items.count, 'Item') %></td>
           <td><%= l(batch.updated_at, format: :short) %></td>
           <td>
-            <% if table_state == 'completed' %>
-              <%= render partial: 'completed_buttons', locals: {batch: batch} %>
-            <% else %>
-              <%= render partial: 'active_buttons', locals: {batch: batch} %>
-            <% end %>
+            <%= render partial: "#{table_state}_buttons", locals: {batch: batch} %>
           </td>

         </tr>
diff --git a/config/application.rb b/config/application.rb
index 563c0b4..7000343 100755
--- a/config/application.rb
+++ b/config/application.rb
@@ -1,7 +1,7 @@
 require_relative 'boot'

 require 'rails/all'
-
+require "font-awesome-rails"
 # Require the gems listed in Gemfile, including any gems
 # you've limited to :test, :development, or :production.
 Bundler.require(*Rails.groups)
diff --git a/spec/features/clearance_batches_spec.rb b/spec/features/clearance_batches_spec.rb
index e2c792f..da5736c 100755
--- a/spec/features/clearance_batches_spec.rb
+++ b/spec/features/clearance_batches_spec.rb
@@ -216,6 +216,96 @@ describe "clearance_batch" do
       end
     end

+    describe 'SORT', js: true do
+      context 'Active Batches' do
+        let!(:active_batch_1) { FactoryBot.create(:active_batch) }
+        let!(:active_batch_2) { FactoryBot.create(:active_batch) }
+        let!(:active_batch_3) { FactoryBot.create(:active_batch) }
+        let!(:active_batch_4) { FactoryBot.create(:active_batch) }
+        let(:item) { FactoryBot.create(:item) }
+
+        it 'default sort updated_at descending' do
+          visit '/'
+          upload_single_item_to_batch(item.id, active_batch_2.id)
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_2.id}"
+          end
+        end
+
+        it 'sorts by updated_at ascending' do
+          visit '/'
+          find('#active-sort-select').find(:xpath, 'option[1]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_1.id}"
+          end
+        end
+
+        it 'sorts by updated_at descending' do
+          visit '/'
+          find('#active-sort-select').find(:xpath, 'option[2]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_4.id}"
+          end
+        end
+
+        it 'sorts by name ascending' do
+          visit '/'
+          find('#active-sort-select').find(:xpath, 'option[3]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_1.id}"
+            expect(page.all('tr')[3].first('td')).to have_content "Active Batch #{active_batch_4.id}"
+          end
+        end
+
+        it 'sorts by name descending' do
+          visit '/'
+          find('#active-sort-select').find(:xpath, 'option[4]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_4.id}"
+            expect(page.all('tr')[3].first('td')).to have_content "Active Batch #{active_batch_1.id}"
+          end
+        end
+
+        it 'sorts by item count ascending' do
+          visit '/'
+          upload_single_item_to_batch(item.id, active_batch_2.id)
+          find('#active-sort-select').find(:xpath, 'option[5]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.all('tr')[3].first('td')).to have_content "Active Batch #{active_batch_2.id}"
+          end
+        end
+
+        it 'sorts by item count descending' do
+          visit '/'
+          upload_single_item_to_batch(item.id, active_batch_2.id)
+          find('#active-sort-select').find(:xpath, 'option[6]').select_option
+          find('#active-sort-btn').click
+          wait_for_ajax
+          within('table.active_table') do
+            expect(page.all('tr').count).to eq 4
+            expect(page.first('tr').first('td')).to have_content "Active Batch #{active_batch_2.id}"
+          end
+        end
+
+      end
+    end
+
   end

   describe 'SHOW', type: :feature do
```
