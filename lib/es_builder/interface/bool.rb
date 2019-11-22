module EsBuilder
  module Interface
    module Bool
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

      # * identical implementation to filter_by
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

      # * identical implementation to filter_by
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

      # * identical implementation to filter_by
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