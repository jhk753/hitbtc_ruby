## Summary

This document provides the complete reference for [hitbtc](https://hitbtc.com) API in the wrapper.


The following symbols are traded on hitbtc exchange.

| Symbol	| Lot size | Price step
| --- | --- | --- |
| BTCUSD |	0.01 BTC |	0.01 |
| BTCEUR |	0.01 BTC |	0.01 |
| LTCBTC | 0.1 LTC |	0.00001 |
| LTCUSD | 0.1 LTC |	0.001 |
| LTCEUR | 0.1 LTC |	0.001 |
| EURUSD | 1 EUR |	0.0001 |

Size representation:
* Size values in streaming messages are represented in lots.
* Size values in RESTful market data are represented in money (e.g. in coins or in USD). 
* Size values in RESTful trade are represented in lots (e.g. 1 means 0.01 BTC for BTCUSD)

### Pending Future Updates

- Solid trade execution functionality
- payment api

Don't hesitate to contribute.
If you liked it:
BTC: 1PizgAWLJbwEsNWG9Cf27skcbgbgZGgeyK
LTC: LQtM1t6BRd64scsdSBk8nnCLJuc8Qfhm53

## Installation

Add this line to your application's Gemfile:

    gem 'hitbtc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hitbtc

## Usage

Create a Kraken client:

```ruby
API_KEY = '3bH+M/nLp......'
API_SECRET = 'wQG+7Lr9b.....'

hitbtc = Hitbtc::Client.new(API_KEY, API_SECRET)

time = hitbtc.server_time
time #=> 1393056191
```
### Public Data Methods

#### Server Time
```ruby
time = hitbtc.server_time

```
#### Symbol info

 ```ruby
 symbol = hitbtc.symbols("BTCEUR")
 symbols = hitbtc.symbols(["BTCEUR", "BTCUSD"])
 all_symbols = hitbtc.symbols
 ```

#### Ticker

```ruby
ticker_data = hitbtc.ticker('BTCEUR')
```

* 24h means last 24h + last incomplete minute
* high - highest trade price / 24 h
* low - lowest trade price / 24 h
* volume - volume / 24h

#### Order Book

```ruby
order_book = hitbtc.order_book('BTCEUR')
order_book = hitbtc.order_book('BTCEUR', {format_amount_unit: "lot"})
```

| Parameter | Type | Description |
| --- | --- | --- |
| format_price | optional, "string" (default) or "number" | |
| format_amount | optional, "string" (default) or "number" | |
| format_amount_unit | optional, "currency" (default) or "lot" | |


#### Trades

```ruby
trades = hitbtc.trades "BTCEUR" (default from 1 day ago, by timestamp, index 0, max_result 1000)
trades = hitbtc.trades 'BTCEUR', (Time.now - 1.day).to_i, "ts", 0, 1000)
trades = hitbtc.trades 'BTCEUR', (Time.now - 1.day).to_i, "ts", 0, 1000, {format_amount_unit: "lot"})
```

Parameters:

| Parameter | Type | Description |
| --- | --- | --- |
| from | required, int, trade_id or timestamp | returns trades with trade_id > specified trade_id <br> returns trades with timestamp >= specified timestamp |
| till | optional, int, trade_id or timestamp | returns trades with trade_id < specified trade_id <br> returns trades with timestamp < specified timestamp |
| by | required, filter and sort by `trade_id` or `ts` (timestamp) | |
| sort | optional, `asc` (default) or `desc` | |
| start_index | required, int | zero-based |
| max_results | required, int, max value = 1000 | |
| format_item | optional, "array" (default) or "object" |  |
| format_price | optional, "string" (default) or "number" | |
| format_amount | optional, "string" (default) or "number" | |
| format_amount_unit | optional, "currency" (default) or "lot" | |
| format_tid | optional, "string" or "number" (default) | |
| format_timestamp | optional, "millisecond" (default) or "second" | |
| format_wrap | optional, "true" (default) or "false" | |


### Private Data Methods

#### Error codes

RESTful Trading API can return the following errors:

| HTTP code | Text | Description |
| --- | --- | --- |
| 403 | Invalid apikey | API key doesn't exist or API key is currently used on another endpoint (max last 15 min) |
| 403 | Nonce has been used | nonce is not monotonous |
| 403 | Nonce is not valid | too big number or not a number |
| 403 | Wrong signature | |

#### Execution reports

The API uses `ExecutionReport` as an object that represents change of order status.

The following fields are used in this object:

| Field	| Description | Type / Enum | Required |
| --- | --- | --- | --- |
| orderId | Order ID on the Exchange | string | required |
| clientOrderId | clientOrderId sent in NewOrder message | string | required |
| execReportType | execution report type | `new` <br> `canceled` <br> `rejected` <br> `expired` <br> `trade` <br> `status` | required |
| orderStatus | order status | `new` <br> `partiallyFilled` <br> `filled` <br> `canceled` <br> `rejected` <br> `expired` | required |
| orderRejectReason | Relevant only for the orders in rejected state | `unknownSymbol` <br> `exchangeClosed` <br>`orderExceedsLimit` <br> `unknownOrder` <br> `duplicateOrder` <br> `unsupportedOrder` <br> `unknownAccount` <br> `other`| for rejects |
| symbol | | string, e.g. `BTCUSD` | required |
| side | | `buy` or `sell` | required |
| timestamp | UTC timestamp in milliseconds | | |
| price | | decimal | |
| quantity | | integer | required |
| type | | only `limit` orders are currently supported | required |
| timeInForce | time in force | `GTC` - Good-Til-Canceled <br>`IOK` - Immediate-Or-Cancel<br>`FOK` - Fill-Or-Kill<br>`DAY` - day orders< | required |
| tradeId | Trade ID on the exchange | | for trades |
| lastQuantity | | integer | for trades |
| lastPrice | | decimal | for trades |
| leavesQuantity | | integer |  |
| cumQuantity | | integer | |
| averagePrice | | decimal, will be 0 if 'cumQuantity'=0 | |


#### Balance

```ruby
all_balance = hitbtc.balance
one_balance = hitbtc.balance("BTC")
many_balances = hitbtc.balance(["BTC", "EUR"])
```

#### List of active orders

```ruby
all_active_orders = hitbtc.active_orders
symbol_specific_orders = hitbtc.active_orders({symbols: "BTCEUR"})
symbols_specific_orders = hitbtc.active_orders({symbols: "BTCEUR,BTCUSD"})
```

Parameters: 

| Parameter | Type | Description |
| --- | --- | --- |
| symbols | string, comma-delimeted list of symbols, optional, default - all symbols | |


#### Create Order

price should be specified even for market execution (haven't tested on a real order yet)

```ruby
hitbtc.create_order({symbol: "BTCEUR", side: "buy", quantity: 1, type: "market", timeInForce: "GTC", price: 320.000})
```

Parameters: 

| Parameter | Type | Description |
| --- | --- | --- |
| symbol | string, required | e.g. `BTCUSD` |
| side | `buy` or `sell`, required | |
| price | decimal, required | order price, required for limit orders |
| quantity | int | order quantity in lots |
| type | `limit` or `market` | order type |
| timeInForce | `GTC` - Good-Til-Canceled <br>`IOK` - Immediate-Or-Cancel<br>`FOK` - Fill-Or-Kill<br>`DAY` - day | use `GTC` by default |



#### Cancel Order

You only need your order id  (haven't been tested on real order yet)

```ruby
hitbtc.cancel_order("1398804347")
```

#### Trades History

```ruby
default = hitbtc.trade_history
custom = hitbtc.trade_history({by: "ts", start_index: 0, max_results: 10, symbols: "BTCEUR,BTCUSD"})
```

Parameters: 

| Parameter | Type | Description |
| --- | --- | --- |
| `by` | `trade_id` or `ts` (timestamp) | |
| `start_index` | int, optional, default(0) | zero-based index |
| `max_results` | int, required, <=1000 | |
| `symbols` | string, comma-delimited | |
| `sort` | `asc` (default) or `desc` | |
| `from` | optional | start `trade_id` or `ts`, see `by` |
| `till` | optional | end `trade_id` or `ts`, see `by` |


#### Recent Orders

```ruby
default = hitbtc.recent_orders
custom = hitbtc.trade_history({start_index: 0, max_results: 10, symbols: "BTCEUR,BTCUSD", statuses: "new,filled"})
```

Parameters: 

| Parameter | Type | Description |
| --- | --- | --- |
| `start_index` | int, optional, default(0) | zero-based index |
| `max_results` | int, required, <=1000 | |
| `symbols` | string, comma-delimited | |
| `statuses` | string, comma-delimited, `new`, `partiallyFilled`, `filled`, `canceled`, `expired`, `rejected` | |

