module Handlers
  def handlers
    @handlers ||= {
      query: {},
      bool: {}
    }
  end

  def set_handler(context: :query, query:, handler: {})
    if handlers[context][query].present?
      handlers[context][query].push(handler)
    else
      handlers[context][query] = [handler]
    end
  end

  def reduce_handlers(data: {}, context: :query)
    filters = data[:filters]
    context_handler = handlers[context]

    return unless context_handler.present?

    context_handler.each.with_object({}) do |(query, handler), hsh|
      next if handler.empty?
      should_pop = context == :query
      reduced_handler = reduce_handler(handler, filters)
      hsh[query] = should_pop ? reduced_handler.pop : reduced_handler
    end
  end

  def reduce_handler(handler, filters)
    handler.map do |handle|
      query_type = handle[:query_type]
      send("build_#{query_type}_query", handle, filters)
    end
  end
end