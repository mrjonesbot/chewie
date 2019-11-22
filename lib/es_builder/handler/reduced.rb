require 'es_builder/query/term_level'
require 'es_builder/query/bool'
require 'es_builder/query/full_text'

module EsBuilder
  module Handler
    class Reduced
      attr_reader :context, :query, :clause, :built_query, :clause_or_query

      def initialize(context:, handler: {}, filters: {})
        @context = context
        @query = handler[:query]
        @clause = handler[:clause]
        @built_query = build_query(handler, filters)
        @clause_or_query = (@clause || @query)
      end

      def reduce_with(handlers, hash)
        has_one = handlers[query].one?

        if has_one && is_top_level_query
          set_in_hash(hash)
        else
          push_to_array(hash)
        end
      end

      private

      def set_in_hash(hash)
        hash[clause_or_query] =
          (hash[clause_or_query] || {}).merge(built_query)
      end

      def push_to_array(hash)
        hash[clause_or_query] =
          (hash[clause_or_query] || []).push(built_query)
      end

      def is_top_level_query
        !(context == :bool && clause.present?)
      end

      def build_query(handler, filters)
        query_type = handler[:query_type]

        case query_type
        when :term_level
          ::EsBuilder::Query::TermLevel.new(handler, filters).build
        when :bool
          ::EsBuilder::Query::Bool.new(handler, filters).build
        when :full_text
          ::EsBuilder::Query::FullText.new(handler, filters).build
        else
          raise "Could not build a query for type: #{query_type}"
        end
      end
    end
  end
end