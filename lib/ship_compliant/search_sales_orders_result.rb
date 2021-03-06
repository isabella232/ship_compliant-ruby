module ShipCompliant
  # === An API wrapper for +SearchSalesOrders+ response.
  #
  # Converts fields into integers and ensures +order_summaries+
  # is an array.
  #
  #   orders = ShipCompliant::SearchSalesOrders.find_by({
  #     purchase_date_min: DateTime.new(2014, 3, 10),
  #     purchase_date_max: DateTime.new(2014, 3, 12)
  #   })
  #
  #   puts orders.length #=> 2
  #
  #   orders.summaries.each do |summary|
  #     puts summary.purchase_date #=> DateTime
  #   end
  class SearchSalesOrdersResult
    include BaseResult
    attr_reader :raw
    alias_method :response, :raw # for BaseResult

    def initialize(data)
      @raw = data
      parse!
    end

    # The number of orders returned the current response.
    def length
      raw.fetch(:count_sales_orders_returned, 0)
    end

    # The number of orders waiting to be returned.
    # Use this for paging results.
    def remaining_orders_length
      raw.fetch(:count_more_sales_orders_available, 0)
    end

    # Returns an array of ShipCompliant::SearchSalesOrderSummary.
    # Use this to get information about each order.
    #
    #   orders.summaries.each do |summary|
    #     puts summary.purchase_date #=> DateTime
    #   end
    def summaries
      raw[:sales_orders][:sales_order_summary].reject(&:blank?).map do |summary|
        SearchSalesOrderSummary.new(summary)
      end
    end

    # Returns the +PagingCookie+ node.
    def paging_cookie
      response[:paging_cookie]
    end

    # Returns the +PagingCookieExpires+ node as DateTime.
    def paging_cookie_expires
      response[:paging_cookie_expires]
    end

    private

    # Standardizes the XML response by converting fields to integers
    # and forcing the order summaries into an array.
    def parse!
      unless raw.has_key?(:sales_orders)
        raw[:sales_orders] = {}
      end

      # force orders to be an array
      orders = raw[:sales_orders].fetch(:sales_order_summary, {})
      unless orders.kind_of?(Array)
        raw[:sales_orders][:sales_order_summary] = [orders]
      end

      # typecast :count_more_sales_orders_available to integer
      if raw.has_key?(:count_more_sales_orders_available)
        convert_to_integer!(:count_more_sales_orders_available, raw)
      end

      # typecast :count_sales_orders_returned to integer
      if raw.has_key?(:count_sales_orders_returned)
        convert_to_integer!(:count_sales_orders_returned, raw)
      end

      raw[:sales_orders][:sales_order_summary].each do |summary|

        # typecast :shipment_key to integer
        if summary.fetch(:shipments, {}).fetch(:shipment_summary, {}).has_key?(:shipment_key)
          convert_to_integer!(:shipment_key, summary[:shipments][:shipment_summary])
        end

        # typecast :zip1 to integer
        if summary.fetch(:shipments, {}).fetch(:shipment_summary, {}).fetch(:ship_to, {}).has_key?(:zip1)
          convert_to_integer!(:zip1, summary[:shipments][:shipment_summary][:ship_to])
        end
      end
    end

    # Typecasts an object key into to an integer.
    #
    #   convert_to_integer(:shipment_key, order_summary[:shipments][:shipment_summary])
    def convert_to_integer!(key, object)
      object[key] = object[key].to_i
    end
  end
end
