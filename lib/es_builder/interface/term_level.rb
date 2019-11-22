module EsBuilder
  module Interface
    module TermLevel
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

      # * tested
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

      # * duplicate implementation as fuzzy
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