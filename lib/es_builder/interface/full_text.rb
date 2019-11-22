module EsBuilder
  module Interface
    module FullText
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