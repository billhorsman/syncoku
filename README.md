# Syncoku

Copies a production Heroku Postgresql database to the local development database or a staging Heroku database. Optionally syncs the production S3 bucket with another bucket.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'syncoku'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install syncoku

## Usage

To copy production to your local development database:
```
syncoku
```

If you have S3 configured it will do the database and S3. To choose just one of those:
```
syncoku db
syncoku s3
```

To target the staging environment:
```
syncoku staging
```

or more simply:
```
syncoku s
```

## Downloading the database (locally)

It will capture a backup of the database and download it to a local file called `.syncoku.dump`. If you run Syncoku a second time and it discovers this file then it will give you the option of reusing it or downloading a new one. Reusing the existing one comes in useful if you have messed around with the local database and want to clean it up.

## Hooks

If you define a rake task called `syncoku:after_sync` then it will automatically be run after the database has been restored and migrated. This is a good place to put anonymization tasks, for instance.

If you want to skip this task, even though it exists:

```
syncoku --skip-after-sync
```

## S3

If you add a file called `syncoku.yml` with the following information, it can sync between S3 buckets too:

```
# syncoku.yml
s3:
  access_key_id: "ABCDEFGH123456789"
  secret_access_key: "a1secret2key3to4access5s3"

  development:
    bucket: "my-bucket-development"

  staging:
    bucket: "my-bucket-staging"

  production:
    bucket: "my-bucket-production"
```

*Note:* a limitation is that that the buckets must use the same credentials.

## Contributing

1. Fork it ( https://github.com/billhorsman/syncoku/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
