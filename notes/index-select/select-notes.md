SELECT SORT NOTES

font-awesome require in app.rb

session variables set in index
  set date-desc as default
sep variable for last active - no code up front. come back to this as an issue
  last active replaces on index form .id

what the sort function
  default order_param to 'date-desc'
  case statement?
  rm sorting from model

table
  set local var order_param with tablest ter.
  two hidden inputs to pass both vars from controller back


js
 write listener for sort on change
 will need to object delegate asp

specs, consider changing index controller to
on diff are a solid start

once green think about refactoring to be more DRY




OLD CODE REFACTOR -

js true default

btn if else => 1 liner with table_state
