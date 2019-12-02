require 'chewie/utils'

module Chewie
  module Query
    class TermLevel
      attr_reader :attribute, :query, :clause, :value, :options, :strategy

      def initialize(handler, filters)
        @attribute = handler[:attribute]
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

      def create_with_attribute
        context(attribute) do
          if value_is_not_a_hash
            { value: value }.merge(options)
          else
            value.merge(options)
          end
        end
      end

      def create_with_clause
        context(query) do
          { attribute => { value: value }.merge(options) }
        end
      end

      def value_is_not_a_hash
        !value.is_a? Hash
      end
    end
  end
end
