# simple_csv_reader

Simple CSV reader.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_csv_reader'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install simple_csv_reader

## Usage

```ruby
# csv_file content
#
# Name,Email Address
# tester1,tester1@csv.test
# tester2,tester2@csv.test

HEADERS = {
  name: 'Name',
  email: 'Email Address',
}.freeze

def import
  SimpleCsvReader.read(csv_file.path, HEADERS) do |row, row_number:|
    User.create!(name: row[:name], email: row[:email])
  end
end
```
