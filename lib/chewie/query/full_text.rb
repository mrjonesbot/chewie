require 'chewie/utils'

module Chewie
  module Query
    class FullText
      attr_reader :attribute, :with, :query, :clause, :value, :options, :strategy

      def initialize(handler, filters)
        @attribute = handler[:attribute]
        @with = handler[:with]
        @query = handler[:query]
        @clause = handler[:clause]
        @value = filters[attribute] || filters[:query]
        @options = handler.fetch(:options, {})
        @strategy = clause.present? ? 'clause' : 'attribute'
      end

      def build
        return {} if value.nil?
        return [] if [value].flatten.empty?

        send("create_with_#{strategy}")
      end

      private

      include Utils

      def create_with_clause
        context(query) do
          multimatch_query? ? multimatch_query : attribute_query
        end
      end

      def create_with_attribute
        return multimatch_query if multimatch_query?

        context(attribute) do
          if !value.is_a? Hash
            { query: value }.merge(options)
          else
            value.merge(options)
          end
        end
      end

      def multimatch_query?
        with.present?
      end

      def attribute_query
        { attribute => { query: value }.merge(options) }
      end
      
      def multimatch_query
        { fields: with, query: value }.merge(options)
      end
    end
  end
end