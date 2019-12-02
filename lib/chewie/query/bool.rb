require 'chewie/utils'

module Chewie
  module Query
    class Bool
      attr_reader :attribute, :query_format, :with, :value, :combine, :filters

      def initialize(handler, filters)
        @attribute = handler[:attribute]
        @query_format = handler[:format]
        @with = handler[:with]
        @value = filters[attribute]
        @combine = handler[:combine]
        @filters = filters
      end

      def build
        return {} if value.nil?
        return [] if [value].flatten.empty?

        context(with) do
          { attribute => exposed_value }
        end
      end

      private

      include Utils

      def should_format
        query_format.present?
      end

      def exposed_value
        expose_or_return_value(formatted_value, with, should_format)
      end

      def formatted_value
        if should_format
          format_values(value, combined, query_format)
        else
          value
        end
      end

      def combined
        combine_values(combine, filters)
      end
    end
  end
end