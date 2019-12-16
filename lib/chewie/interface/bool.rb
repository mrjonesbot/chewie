module Chewie
  module Interface
    module Bool
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param with [Symbol] Specify the term-level query [term, terms, range]
      # @param combine [Array] Target additional filter values to be combined in the formatted output (optional)
      # @param format [Lambda] Define custom output with :combine values at runtime (optional)
      # @return [Hash] A valid bool query
      # @note See README#filtering-by-associations use case for :combine and :filter options
      def filter_by(attribute, with:, combine: [], format: nil)
        handler = {
          query: :filter,
          attribute: attribute, 
          with: with,
          combine: combine, 
          format: format,
          query_type: :bool,
        }
        set_handler(context: :bool, handler: handler)
      end

      # (see #filter_by)
      def should_include(attribute, with:, combine: [], format: nil)
        handler = {
          query: :should,
          attribute: attribute, 
          with: with,
          combine: combine, 
          format: format,
          query_type: :bool,
        }
        set_handler(context: :bool, handler: handler)
      end

      # (see #filter_by)
      def must_not_include(attribute, with:, combine: [], format: nil)
        handler = {
          query: :must_not,
          attribute: attribute, 
          with: with,
          combine: combine, 
          format: format,
          query_type: :bool,
        }
        set_handler(context: :bool, handler: handler)
      end

      # (see #filter_by)
      def must_include(attribute, with:, combine: [], format: nil)
        handler = {
          query: :must,
          attribute: attribute, 
          with: with,
          combine: combine, 
          format: format,
          query_type: :bool,
        }

        set_handler(context: :bool, handler: handler)
      end
    end
  end
end