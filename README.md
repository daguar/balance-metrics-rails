# Balance Metrics (v2 — Rails)

An infrastructure for metrics for Balance, using Postgres and Balance

## Setup

Turn on your local Postgres instance and set your credentials:

- POSTGRES_USERNAME
- POSTGRES_PASSWORD


Set the necessary environment variables using Twilio's production credentials:

- TWILIO_BALANCE_PROD_SID
- TWILIO_BALANCE_PROD_AUTH

Set the necessary environment variables for [plotly](http://plot.ly/) credentials:

- PLOTLY_USERNAME
- PLOTLY_KEY

Clone the repo, go into the directory, and install dependencies:

`bundle install`


Set up the database:

```
bundle exec rake db:create
bundle exec rake db:migrate
```

Load data from Twilio in a super janky way for now:

Open up the Rails console:

`rails c`

Then run this:

`TwilioImporter.new.load_messages!`


