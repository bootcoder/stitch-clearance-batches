## Stitch Fix Take Home Challenge

### Development Notes from Hunter T. Chapman:

#### Intro:

Hi! And thanks for taking time to review my code.

There are more casual comments strewn about than is my norm. I felt it OK to justify things for you the reviewer as I went, since we have no pre-established feedback loop.

Search through the project for case-sensitive 'NOTE:' to see specific comments left for you.

#### Git

Inspection. If you want to run a diff on my code. (Since we won't be opening a PR on GitHub) I suggest using:

```bash
git diff 5eec546 ':(exclude)public/assets/*'
```

This will show the work from my current commit back to the initial commit and will leave off all the messy rails code that doesn't belong to me anyhow.

Ordinarily I would clean this up and squash these 60 or so commits down into 3-4 before opening a PR.

I left them in their granular form here so you could better see my flow if you desire. That said, I'd also like to mention that I could have (and usually do) committed more often.


#### Build mentality:

If I needed something I built it. Not because I can't use tons of libraries, but because I felt it best to show you what I can do to the greatest extent possible. No leaning on jQuery to enhance UI, no gems for simple tasks like forms, or any other 'helper' type things. The largest library I am utilizing is wicked_pdf.

I've been building a lot of React as of late. I think that had an effect on my views as they are more modular (and thus more bountiful) than I recall from past Rails projects. That said, I considered scraping the front-end, converting to JSONic Rails and doing a quick set of React views. Honestly I think it would have been quicker, cleaner and easier to build upon.

I read the README thoroughly and tried to conform in every possible way. In this instance, I felt it was a 'cool thing' that didn't meet the bar.

The CSS transition of the help div in lieu of JS however is a cool thing I can pull off! 😎 It wasn't just for giggles though, it's also functional, using CSS in this case was important as I did not want to introduce any code which would alter the user experience if JS fails.

#### General Notes:

The biggest thing to talk about is what you're probably thinking right now... 'What is an Active Batch? Why do we need it?'

A large design decision around active VS completed ClearanceBatches
came up as I was considering how to build out the app.

I felt if a user is adding items via a scan tool they would most likely need
to add items to different clearance batches at different times. This need bore
out the requirements which drove a significant portion of the development thereafter.

I felt the best way to represent these states was with a flag attached to the batch itself.
To do so cleanly I made a change in the schema. Along with doubling the number of tables displayed on index.

I could have accomplished my goal without these departures from the original product. Implementation would have been icky and not in line with the 'Rails Way'. And since the README specifically states changing schema as an option I felt it OK. Side Note on migrations, I originally called Active attr Open. That was a poor attr name choice. I removed that migration before submission. Just saying I know in real life you shouldn't go back and rm old migrations.

Specifically to that tables, Just one table displaying both batch states would be cumbersome for the user as the app scales.

Overall I maintain ```active_batches``` was a solid choice as the increase in usability and functionality is substantial.

-----

Originally, I looked at the reqs, and said 'Piece of Cake. I'll just generate a show for reports and ajax a new form field'.
But I decided there was opportunity for more. Adding PDF,CSV, and HTML reports seemed like a good challenge beyond the stated reqs that didn't go 'too far'

-----

Table Design: Getting the tables to scroll two wide was an journey. I think the result is good though. The current design allows for minimum vertical departure from the core element (input form) as the user traverses what could be thousands of completed batches.

I gave considerable thought to adding sortable table headers or a sort_by dropdown. Seemed non-MVP so I decided against it. Currently the lists always sort by most recently updated. Also in case you're thinking it, Table headers on index seemed like wasted space given how little data is displayed on them.

Side styling note: App is fully responsive but not 'Mobile First', although I could foresee a real-world version of this transitioning to mobile to allow for on the go scan and clearance functionality.

-----

I took the opportunity to refactor your existing code. ```ClearancingService``` in particular is much cleaner while providing enhanced functionality and easing the burden on the ```ClearanceBatchesController``` dramatically. ```ClearancingService``` now handles: all input types, generates the bulk of flash messages for the controller#create, and is much easier to read / test.

At first I left ```ClearancingService``` alone, just modifying it a scoach to handle items. After I hit MVP I gave it another look and decided there was a lot of room for growth.

I left your specs as is as much as I could, they're your specs after all.

-----

Since we have no CI tool here, I'm using Guard / Guard-Rspec as my continuous integration equivalent.

-----

If you're uploading the same sample CSV you sent out. It still works, but you will find the results are different. This is because I am seeding the DB with both batch types for demo purposes.


#### Testing

Mostly I TDD'd the app. There were a few instances of adding the spec after the fact. For instance, I wasn't sure what I expected back from CSV render until I made it happen.

Specs include:
- Full Feature coverage
- Full Controller coverage
- Full Model coverage

Included or upgraded the following gems for testing:
  - rspec-rails
  - factory_bot_rails
  - capybara
  - poltergeist
  - database_cleaner
  - selenium-webdriver
  - shoulda-matchers
  - rails-controller-testing
  - simplecov
  - guard
  - guard-rspec


**After you run the specs** a [SimpleCov report](./coverage/index.html) is generated, 100% coverage.

#### One more thing

<img src="https://media.giphy.com/media/16tNp8LB7MS0o/giphy.gif" />
