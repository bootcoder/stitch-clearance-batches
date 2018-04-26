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
diff --git a/app/assets/stylesheets/application.scss b/app/assets/stylesheets/application.scss
index bd4fc88..bece950 100755
--- a/app/assets/stylesheets/application.scss
+++ b/app/assets/stylesheets/application.scss
@@ -1,6 +1,7 @@
 @import "bootstrap";
 @import "index";
 @import "report";
+@import "font-awesome";

 // NOTE: The first line of CSS I write in any app. Such a lifesaver.
 // Usually would remove before production but leaving for you.
diff --git a/app/assets/stylesheets/index.scss b/app/assets/stylesheets/index.scss
index 4682e52..e1d9c36 100644
--- a/app/assets/stylesheets/index.scss
+++ b/app/assets/stylesheets/index.scss
@@ -95,3 +95,11 @@ h1 a:hover {
   max-height: 30px;
   max-width: 30px;
 }
+
+.sort-group p {
+  margin: 0;
+}
+
+.btn-sort {
+  display: block;
+}
diff --git a/app/controllers/clearance_batches_controller.rb b/app/controllers/clearance_batches_controller.rb
index c9090af..dc92146 100755
--- a/app/controllers/clearance_batches_controller.rb
+++ b/app/controllers/clearance_batches_controller.rb
@@ -5,8 +5,12 @@ class ClearanceBatchesController < ApplicationController
   # Started out with several Ajax views but ultimately decided things were small
   # enough to simply re-render index asynchronously
   def index
-    @active_batches = ClearanceBatch.active
-    @completed_batches  = ClearanceBatch.completed
+    session[:active_sort] = clearance_params[:active_sort] || session[:active_sort]
+    session[:completed_sort] = clearance_params[:completed_sort] || session[:completed_sort]
+
+    @active_batches = what_the_sort(ClearanceBatch.active, session[:active_sort])
+    @completed_batches  = what_the_sort(ClearanceBatch.completed, session[:completed_sort])
+    @last_active_batch = ClearanceBatch.active.order(:updated_at).last

     respond_to do |format|
       format.html
@@ -94,7 +98,28 @@ class ClearanceBatchesController < ApplicationController

   # NOTE: Added Strong params because..... That's what you do. :-)
   def clearance_params
-    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch)
+    params.permit(:csv_file, :item_id, :batch_id, :close_batch, :activate_batch, :active_sort, :completed_sort)
   end

+  def what_the_sort(batch, sort_param)
+    case sort_param
+    when 'date-asc'
+      return batch.order(:updated_at)
+    when 'items-asc'
+      return batch.sort_by { |b| b.items.count }.reverse
+    when 'items-desc'
+      return batch.sort_by { |b| b.items.count }
+    when 'id-asc'
+      return batch.order(:id)
+    when 'id-desc'
+      return batch.order(id: :desc)
+    else
+      return batch.order(updated_at: :desc)
+
+    end
+  end
+
+
+
+
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
diff --git a/app/views/clearance_batches/_table.html.erb b/app/views/clearance_batches/_table.html.erb
index 85cd94a..363a1f8 100644
--- a/app/views/clearance_batches/_table.html.erb
+++ b/app/views/clearance_batches/_table.html.erb
@@ -3,11 +3,29 @@
 <!-- I'm not pleased with readability as a result.. -->
 <!-- Also Yes I agree, one should not ordinarily leave a comment in HTML -->

-<% if table_state == 'completed' %>
-  <h3 class='table-title text-success'>Completed Batches</h3>
-<% else %>
-  <h3 class='table-title text-danger'>Active Batches</h3>
-<% end %>
+<div class='row'>
+  <% if table_state == 'completed' %>
+    <h4 class='table-title text-success col-md-5'>Completed Batches</h4>
+  <% else %>
+    <h4 class='table-title text-danger col-md-5'>Active Batches</h4>
+  <% end %>
+
+    <div class='col-md-2 text-center sort-group'>
+      <%= link_to fa_icon('sort-asc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'id-asc'), method: :get, remote: true, class: 'btn-id-asc btn-sort' %>
+      <p>ID</p>
+      <%= link_to fa_icon('sort-desc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'id-desc'), method: :get, remote: true, class: 'btn-id-desc btn-sort' %>
+    </div>
+    <div class='col-md-2 text-center sort-group'>
+      <%= link_to fa_icon('sort-asc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'items-asc'), method: :get, remote: true, class: 'btn-items-asc btn-sort' %>
+      <p>Items</p>
+      <%= link_to fa_icon('sort-desc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'items-desc'), method: :get, remote: true, class: 'btn-items-desc btn-sort' %>
+    </div>
+    <div class='col-md-2 text-center sort-group'>
+      <%= link_to fa_icon('sort-asc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'date-asc'), method: :get, remote: true, class: 'btn-date-asc btn-sort' %>
+      <p>Date</p>
+      <%= link_to fa_icon('sort-desc', class: 'fa-2x'), clearance_batches_path("#{table_state}_sort" => 'date-desc'), method: :get, remote: true, class: 'btn-date-desc btn-sort' %>
+    </div>
+</div>

 <div class='table-container'>
   <table class="table table-responsive table-striped <%= table_state %>_table">
diff --git a/config/application.rb b/config/application.rb
index 563c0b4..0dc43f3 100755
--- a/config/application.rb
+++ b/config/application.rb
@@ -6,6 +6,8 @@ require 'rails/all'
 # you've limited to :test, :development, or :production.
 Bundler.require(*Rails.groups)

+require 'font-awesome-rails'
+
 module TakeHomeChallenge
   class Application < Rails::Application
     # Initialize configuration defaults for originally generated Rails version.
diff --git a/config/initializers/new_framework_defaults_5_1.rb b/config/initializers/new_framework_defaults_5_1.rb
index ad5490f..c21e6ee 100755
--- a/config/initializers/new_framework_defaults_5_1.rb
+++ b/config/initializers/new_framework_defaults_5_1.rb
@@ -7,7 +7,7 @@
 # Read the Guide for Upgrading Ruby on Rails for more info on each option.

 # Make `form_with` generate non-remote forms.
-Rails.application.config.action_view.form_with_generates_remote_forms = true
+Rails.application.config.action_view.form_with_generates_remote_forms = false

 # Enable per-form CSRF tokens. Previous versions had false.
 Rails.application.config.action_controller.per_form_csrf_tokens = false
diff --git a/spec/controllers/clearance_batches_controller_spec.rb b/spec/controllers/clearance_batches_controller_spec.rb
index d676e06..93d7f72 100644
--- a/spec/controllers/clearance_batches_controller_spec.rb
+++ b/spec/controllers/clearance_batches_controller_spec.rb
@@ -13,6 +13,7 @@ describe ClearanceBatchesController, type: :controller do
     it "assigns all batches" do
       expect(assigns(:completed_batches)).to eq [batch_2, batch_1]
       expect(assigns(:active_batches)).to eq [active_batch]
+      expect(assigns(:last_active_batch)).to eq active_batch
     end

     it "renders the index template with 200" do
diff --git a/spec/features/clearance_batches_spec.rb b/spec/features/clearance_batches_spec.rb
index e2c792f..3fd207a 100755
--- a/spec/features/clearance_batches_spec.rb
+++ b/spec/features/clearance_batches_spec.rb
@@ -216,6 +216,203 @@ describe "clearance_batch" do
       end
     end

+    describe 'SORT', js: true do
+
+      context "Edge Cases" do
+        let!(:batch_1) { FactoryBot.create(:active_batch) }
+        let!(:batch_2) { FactoryBot.create(:active_batch) }
+        let!(:completed_batch_1) { FactoryBot.create(:clearance_batch_with_items) }
+        let!(:completed_batch_2) { FactoryBot.create(:clearance_batch) }
+
+        it "Active sort persists when sorting completed" do
+          visit '/'
+          within('#active_table_container') do
+            find('.btn-id-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_1.id}"
+          end
+          within('#completed_table_container') do
+            find('.btn-items-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "Does not alter batch select on table sort" do
+
+        end
+      end
+
+      context "Active Batches" do
+        let!(:batch_1) { FactoryBot.create(:active_batch) }
+        let!(:batch_2) { FactoryBot.create(:active_batch) }
+        let!(:batch_3) { FactoryBot.create(:active_batch) }
+        let!(:batch_4) { FactoryBot.create(:active_batch) }
+        let(:item)     { FactoryBot.create(:item) }
+
+        it "defaults to updated_at descending" do
+          visit '/'
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_4.id}"
+          end
+        end
+
+        it "by ID ascending" do
+          visit '/'
+          within('#active_table_container') do
+            find('.btn-id-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "by ID descending" do
+          visit '/'
+          within('#active_table_container') do
+            find('.btn-id-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.all('tr')[3]).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "by items count ascending" do
+          visit '/'
+          upload_single_item_to_batch(item.id, batch_1.id)
+          within('#active_table_container') do
+            find('.btn-items-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "by items count descending" do
+          visit '/'
+          upload_single_item_to_batch(item.id, batch_1.id)
+          within('#active_table_container') do
+            find('.btn-items-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.all('tr')[3]).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "by updated_at ascending" do
+          visit '/'
+          within('#active_table_container') do
+            find('.btn-date-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_1.id}"
+          end
+        end
+
+        it "by updated_at descending" do
+          visit '/'
+          within('#active_table_container') do
+            find('.btn-date-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.active_table') do
+            expect(page.first('tr')).to have_content "Active Batch #{batch_4.id}"
+          end
+        end
+
+      end
+
+      context "Completed Batches" do
+        let!(:batch_1) { FactoryBot.create(:clearance_batch_with_items) }
+        let!(:batch_2) { FactoryBot.create(:clearance_batch) }
+        let!(:batch_3) { FactoryBot.create(:clearance_batch) }
+        let!(:batch_4) { FactoryBot.create(:clearance_batch) }
+
+        it "defaults to updated_at descending" do
+          visit '/'
+          within('table.completed_table') do
+            expect(page.first('tr')).to have_content "Batch #{batch_4.id}"
+          end
+        end
+
+        it "by ID ascending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-id-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.first('tr')).to have_content "Batch #{batch_1.id}"
+          end
+        end
+
+        it "by ID descending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-id-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.all('tr')[3]).to have_content "Batch #{batch_1.id}"
+          end
+        end
+
+        it "by items count ascending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-items-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.first('tr')).to have_content "Batch #{batch_1.id}"
+          end
+        end
+
+        it "by items count descending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-items-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.all('tr')[3]).to have_content "Batch #{batch_1.id}"
+          end
+        end
+
+        it "by updated_at ascending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-date-asc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.first('tr')).to have_content "Batch #{batch_1.id}"
+          end
+        end
+
+        it "by updated_at descending" do
+          visit '/'
+          within('#completed_table_container') do
+            find('.btn-date-desc').trigger('click')
+            wait_for_ajax
+          end
+          within('table.completed_table') do
+            expect(page.first('tr')).to have_content "Batch #{batch_4.id}"
+          end
+        end
+
+      end
+    end
+
   end

   describe 'SHOW', type: :feature do

```
