## Stitch Fix Take Home Challenge
### Development Notes:

#### Intro:

Hi! And thanks for taking time to review my code.

There are more casual comments in this code base than my norm.

I felt it OK to justify things for you the reviewer as I went, since we have no pre-established feedback loop.

Search through the project for case-sensitive 'NOTE:' to see specific comments left for you.

#### Build mentality:

If I needed something I built it. No leaning on jQuery to enhance UI, no gems for simple tasks like forms, or any other 'helper' type things. The largest library I am utilizing is wicked_pdf.

I'll admit, I haven't built just a full-stack rails app in some time. Mostly React and Rails API's.

I think that had an effect on my views as they are more modular (and thus more bountiful) than I recall from past Rails projects. That said, I considered scraping the front-end, converting to JSONic Rails and doing a quick set of React views. Honestly I think it would have been quicker, cleaner and easier to build upon. I read the README thoroughly and tried to conform in every possible way. In this instance, I felt it was a 'cool thing' that didn't meet the bar.

#### Testing
Mostly I TDD'd the app. There were a few instances of adding the spec after the fact. For instance, I wasn't sure what I expected back CSV render.

Specs include:
- Full Feature coverage
- Full Controller coverage


#### Design Decisions:

You may be wondering 'What is an In Progress Batch?'

A large design decision around in_progress VS completed ClearanceBatches
came up as I was considering how to build out the app.
I felt if a user is adding items via a scan tool they would most likely need
to add items to different clearance batches at different times. This need bore
out the requirements which drove a significant portion of the development thereafter.

I felt the best way to represent these states was with a flag attached to the batch itself.
To do so cleanly required a change in the schema. Along with doubling the number of tables displayed on index.
Overall I maintain this was a solid choice as the functionality added is substantial.

-----

Originally, I looked at the reqs, and said 'Piece of Cake. I'll just generate a show for reports and ajax a new form field'.
But I decided there was opportunity for more. Adding PDF,CSV, and HTML reports seemed like a good challenge that didn't go 'too far'

-----

Styling wise, Getting the tables to scroll two wide was an journey. I think the result is good though.
The current design allows for minimum departure from the core element (input form) as the user traverses what could be thousands of completed batches.

-----

I took the opportunity to refactor a bit of your existing code as well.
In particular, I think the ClearancingService is much cleaner
while providing enhanced functionality and easing the burden on the controller.
I left your specs as is as much as I could, they're your specs.

-----

Things left unsaid, the code path not traveled.
