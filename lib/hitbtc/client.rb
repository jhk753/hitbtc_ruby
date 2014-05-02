require 'httparty'
require 'hashie'
require 'base64'
require 'addressable/uri'


module Hitbtc
  class Client
    include HTTParty

    def initialize(api_key=nil, api_secret=nil, options={})
      @api_key      = api_key || YAML.load_file("key.yml")["key"]
      @api_secret   = api_secret || YAML.load_file("key.yml")["secret"]
      @api_version  = options[:version] ||= '1'
      @base_uri     = options[:base_uri] ||= 'api.hitbtc.com'
    end

    ###########################
    ###### Public Data ########
    ###########################

    def server_time
      mash = get_public 'time'
      mash.try(:timestamp)
    end

    def symbols(opts={}) #can specify array of string symbols
      mash = get_public 'symbols'
      m = mash.try(:symbols)
      if (opts.length == 1 || opts.class == String) && m != mash
        m.select{|h| opts.include?(h.symbol)}.first
      elsif !opts.empty? && m != mash
        m.select{|h| opts.include?(h.symbol)}
      else
        m
      end
    end

    def ticker symbol
      checked_symbol = check_symbol(symbol)
      get_public(checked_symbol+"/ticker")
    end

    def order_book symbol, opts={}
      checked_symbol = check_symbol(symbol)
      #opts optional
      #format_price: "string" (default) or "number"
      #format_amount: "string" (default) or "number"
      #format_amount_unit: "currency" (default) or "lot"
      get_public(checked_symbol+"/orderbook", opts)
    end

    def trades symbol, from = (Time.now - 1.day).to_i, by = "ts", start_index = 0, max_results = 1000, opts={}
      checked_symbol = check_symbol(symbol)
      #Parameter                    Type                            Description
      #from	required                int = trade_id or timestamp	    returns trades with trade_id > specified trade_id or returns trades with timestamp >= specified timestamp
      #till	optional                int = trade_id or timestamp	    returns trades with trade_id < specified trade_id or returns trades with timestamp < specified timestamp
      #by	required                  filter and sort by trade_id or ts (timestamp)
      #sort	optional                asc (default) or desc
      #start_index required         int	zero-based
      #max_results required         int, max value = 1000
      #format_item optional         "array" (default) or "object"
      #format_price	optional        "string" (default) or "number"
      #format_amount optional       "string" (default) or "number"
      #format_amount_unit optional  "currency" (default) or "lot"
      #format_tid	optional          "string" or "number" (default)
      #format_timestamp	optional    "millisecond" (default) or "second"
      #format_wrap optional         "true" (default) or "false"
      if by != "trade_id" && by != "ts"
        raise "3rd parameter by, should be 'trade_id' or 'ts'"
      end
      opts[:from] = from
      opts[:start_index] = start_index
      opts[:max_results] = max_results
      opts[:by] = by
      mash= get_public(checked_symbol+'/trades', opts)
      mash.try(:trades)
    end

    def get_public(method, opts={})
      url = 'http://'+ @base_uri + '/api/' + @api_version + '/public/' + method
      r = self.class.get(url, query: opts)
      Hashie::Mash.new(JSON.parse(r.body))
    end

    ######################
    ##### Private Data ###
    ######################

    def balance opts={} #array of string currency
      mash = get_private 'balance'
      m = mash.try(:balance)
      if opts.class == String
        o = []
        o << opts
        opts = o
      end
      if m != mash && opts.length > 0
        r= m.select{|c| opts.include?(c.currency_code)}
        (r.length==1 ? r.first : r)
      else
        m
      end
    end

    def active_orders opts={} #symbols: string comma-delimeted list of symbols, optional, default - all symbols
      #example {:symbols=> "BTCEUR,BTCUSD"}
      mash = get_private 'orders/active', opts
      mash.try(:orders)
    end

    def cancel_order client_order_id
      orders = active_orders
      order = orders.select{|o| o.orderId == client_order_id}.try(:first)
      if order.nil?
        "We didn't find the order for the specified ID"
      else
        opts = {}
        opts[:clientOrderId] = order.orderId
        opts[:cancelRequestClientOrderId] = Time.now.to_i.to_s
        opts[:symbol] = order.symbol
        opts[:side] = order.side
        opts[:price] = order.orderPrice
        opts[:quantity] = order.orderQuantity
        opts[:type] = order.limit
        opts[:timeInForce] = order.timeInForce

        get_private 'cancel_order', opts
      end
    end

    def trade_history opts={by:"ts", start_index: 0, max_results: 10}
      mash= get_private 'trades', opts
      mash.try(:trades)
    end

    def recent_orders opts={max_results: 10, start_index: 0, statuses: "new,partiallyFilled,filled,canceled,expired,rejected"}
      mash = get_private 'orders/recent', opts
      mash.try(:orders)
    end

    #### Private User Trading (Still experimental!) ####
    def create_order opts={}
      opts[:clientOrderId] = Time.now.to_i.to_s
      post_private 'new_order', opts
    end
    ######################
    ##### Payment Data ###
    ######################

    # to be written

    #######################
    #### Generate Signed ##
    ##### Post Request ####
    #######################

    private

    def post_private(method, opts={})
      post_data = encode_options(opts)
      uri = "/api/"+ @api_version + "/trading/" + method +"?" + "apikey=" + @api_key + "&nonce=" + nonce
      url = "https://" + @base_uri + uri
      signature = generate_signature(uri, post_data)
      headers = {'X-Signature' => signature}
      r = self.class.post(url, {headers: headers, body: post_data}).parsed_response
      Hashie::Mash.new(r)
    end

    def get_private(method, opts={})
      opts = complete_opts(opts)
      uri = "/api/"+ @api_version + "/trading/" + method +"?" + encode_options(opts)
      url = "https://" + @base_uri + uri
      signature = generate_signature(uri, "")
      headers = {'X-Signature' => signature}



      r = self.class.get(url, {headers: headers})
      mash = Hashie::Mash.new(JSON.parse(r.body))
    end

    def complete_opts opts
      opts[:apikey] = @api_key
      opts[:nonce] = nonce
      opts
    end

    def nonce
      DateTime.now.strftime('%Q')
    end

    def encode_options(opts)
      uri = Addressable::URI.new
      uri.query_values = opts
      uri.query
    end

    def generate_signature(uri, post_data)
      message = generate_message(uri, post_data)
      generate_hmac(@api_secret, message)
    end

    def generate_message(uri, data)
        uri + data
    end

    def generate_hmac(key, message)
      OpenSSL::HMAC.hexdigest('SHA512', key, message).downcase
    end

    def check_symbol symbol
      if symbol.length != 6 || symbol.class != String
        raise "You didn't enter a correct symbol, check symbols method to see list and enter symbol as a string"
      end
      symbol.upcase
    end

    def random_string

    end

    ##################################
    ##### Realtime with web socket ###
    ##################################

    # to be written

  end
end

class Hashie::Mash
    def try key
       if self.key?(key.to_s)
         self[key]
       else
         self
       end
    end
end
