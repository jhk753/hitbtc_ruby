require 'httparty'
require 'hashie'
require 'Base64'
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
      hash = get_public 'time'
      hash.timestamp
    end

    def symbols(opts={}) #can specify array of string symbols
      hash = get_public 'symbols'
      if opts.empty?
         hash.symbols
      elsif opts.length == 1 || opts.class == String
        hash.symbols.select{|h| opts.include?(h.symbol)}.first
      else
        hash.symbols.select{|h| opts.include?(h.symbol)}
      end
    end

    def ticker symbol
      get_public(symbol+"/ticker")
    end

    def order_book symbol, opts={}
      #opts optional
      #format_price: "string" (default) or "number"
      #format_amount: "string" (default) or "number"
      #format_amount_unit: "currency" (default) or "lot"
      get_public(symbol+"/orderbook", opts)
    end

    def trades symbol, opts={}
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
      get_public(symbol+'/trades', opts)
    end

    def get_public(method, opts={})
      url = 'http://'+ @base_uri + '/api/' + @api_version + '/public/' + method
      p url
      r = self.class.get(url, opts)
      hash = Hashie::Mash.new(JSON.parse(r.body))
    end

    ######################
    ##### Private Data ###
    ######################

    def balance
      get_private 'balance'
    end

    def active_orders(opts={}) #symbols: string comma-delimeted list of symbols, optional, default - all symbols
      get_private 'orders/active', opts
    end

    def cancel_order(opts={})
      get_private 'cancel_order', opts
    end

    def trade_history(opts={})
      get_private 'trades', opts
    end

    def recent_orders(opts={})
      get_private 'orders/recent'
    end

    #### Private User Trading (Still experimental!) ####
    def create_order(opts={})
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
      opts['nonce'] = nonce
      opts['apikey'] = @api_key
      post_data = encode_options(opts)
      opts['signature'] = generate_signature(url_path(method), post_data)

      signed_data = encode_options(opts)

      url = "https://" + @base_uri + url_path(method)
      r = self.class.post(url, { body: signed_data }).parsed_response
      r['error'].empty? ? Hashie::Mash.new(r['result']) : r['error']
    end

    def get_private(method, opts={})
      opts['nonce'] = nonce
      opts['apikey'] = @api_key
      post_data = encode_options(opts)
      opts['signature'] = generate_signature(url_path(method), post_data)

      url = "https://" + @base_uri + url_path(method)

      r = self.class.get(url, opts)
      hash = Hashie::Mash.new(JSON.parse(r.body))
      hash[:result]
    end

    def nonce
      Time.now.to_i.to_s.ljust(16,'0')
    end

    def encode_options(opts)
      uri = Addressable::URI.new
      uri.query_values = opts
      uri.query
    end

    def generate_signature(method, post_data)
      key = Base64.decode64(@api_secret)
      message = generate_message(method, post_data)
      generate_hmac(key, message).downcase
    end

    def generate_message(method, data)
      url_path(method) + data
    end

    def generate_hmac(key, message)
      Base64.strict_encode64(OpenSSL::HMAC.digest('sha512', key, message))
    end

    def url_path(method)
      '/api/' + @api_version + '/trading/' + method
    end


    ##################################
    ##### Realtime with web socket ###
    ##################################

    # to be written

  end
end