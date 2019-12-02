module Utils
  def set_handler(context: :query, handler: {})
    if handlers[context].present?
      handlers[context].push(handler)
    else
      handlers[context] = [handler]
    end
  end

  def reduce_handlers(data: {}, context: :query)
    filters = data[:filters]
    context_handlers = handlers[context]

    return unless context_handlers.present?

    grouped_handlers = context_handlers.group_by {|h| h[:query] }

    context_handlers.each.with_object({}) do |handler, hsh|
      next if handler.empty?

      handler = Chewie::Handler::Reduced.
        new(context: context, handler: handler, filters: filters)

      handler.reduce_with(grouped_handlers, hsh)
    end
  end

  def context(key, **options)
    options.merge(key => yield)
  end

  def set_query_data(query, filters)
    { filters: clean_filters(filters).merge(query: query) }
  end

  def clean_filters(filters)
    filters.reject do |_, value|
      value.nil?
    end.with_indifferent_access
  end

  def combine_values(keys, filters)
    keys.map { |key| filters[key] }
  end

  def format_values(values, combine, format)
    [values].flatten.map do |value|
      combine.any? ? format.call(value, combine) : format.call(value)
    end
  end

  def expose_or_return_value(value, with, should_format)
    is_term = with == :term
    is_term && should_format ? value.pop : value
  end
end