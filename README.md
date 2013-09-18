# Itagami

Rakuten Securities client library for algorithmic trading.

Features:

* Login to "https://mobile.rakuten-sec.co.jp/".
* Get stock info.
* Get board info.
* Buy/Sell at the market.

## Installation

Add this line to your application's Gemfile:

    gem 'itagami'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install itagami

## Usage

To initialize:

```ruby
require 'itagami'
itagami = MobileItagami.new
```

To login:

```ruby
itagami.login
```

To get stock info:

```ruby
itagami.get_stock_info(1234)
```

To get board info:

```ruby
itagami.get_board(1234)
```

To buy at the market:

```ruby
itagami.buy_immediately(1234, 1)
```

To sell at the market:

```ruby
itagami.sell_immediately(1234, 1)
```

To logout:

```ruby
itagami.logout
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
