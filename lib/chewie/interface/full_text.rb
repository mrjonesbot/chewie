module Chewie
  module Interface
    module FullText
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html
      # 
      # @param attribute [Symbol] Field you wish to search
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Hash] Options to augment search behavior: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html#match-field-params
      # @return [Hash] A valid "must" query
      def match(attribute, context: :query, clause: nil, options: {})
        handler = {
          query: :match,
          clause: clause,
          attribute: attribute,
          query_type: :full_text,
          options: options,
        }

        set_handler(context: context, handler: handler)
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-multi-match-query.html
      # 
      # @param with [Array] A collection of field symbols to match against
      # @param context [Symbol] Desired context the query should appear (see https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)
      # @param clause [Symbol] Specify a nested clause, usually context dependent (optional)
      # @param options [Hash] Options to augment search behavior
      # @return [Hash] A valid "multi-match" query
      def multimatch(with: [], context: :query, clause: nil, options: {})
        if context == :compound
          raise 'Please include a :clause value for compound queries.'
        end

        handler = {
          query: :multimatch,
          clause: clause,
          with: with,
          query_type: :full_text,
          options: options,
        }

        set_handler(context: context, handler: handler)
      end
    end
  end
end