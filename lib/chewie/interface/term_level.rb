module Chewie
  module Interface
    module TermLevel
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Lambda] Options to augment search behavior: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html#fuzzy-query-field-params
      # @return [Hash] A valid "fuzzy" query
      def fuzzy(attribute, context: :query, clause: nil, options: {})
        handler = {
          query: :fuzzy,
          clause: clause,
          attribute: attribute,
          query_type: :term_level,
          options: options,
        }
        set_handler(context: context, handler: handler)
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Lambda] Options to augment search behavior: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html#range-query-field-params
      # @return [Hash] A valid "range" query
      def range(attribute, context: :query, clause: nil, options: {})
        handler = {
          query: :range,
          clause: clause,
          attribute: attribute,
          query_type: :term_level,
          options: options
        }

        set_handler(context: context, handler: handler)
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Lambda] Options to augment search behavior: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-term-query.html#term-field-params
      # @return [Hash] A valid "term" query
      def term(attribute, context: :query, clause: nil, options: {})
        handler = {
          query: :term,
          clause: clause,
          attribute: attribute,
          query_type: :term_level,
          options: options
        }

        set_handler(context: context, handler: handler)
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Lambda] Options to augment search behavior: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html#terms-top-level-params
      # @return [Hash] A valid "terms" query
      def terms(attribute, context: :query, clause: nil, options: {})
        handler = {
          query: :terms,
          clause: clause,
          attribute: attribute,
          query_type: :term_level,
          options: options
        }

        set_handler(context: context, handler: handler)
      end
    end
  end
end