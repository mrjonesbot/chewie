module Handlers
  def handlers
    @handlers ||= {
      query: [],
      bool: []
    }
  end

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

    # grouped_handlers = context_handlers.group_by {|h| h[:query] }

    context_handlers.each.with_object({}) do |handler, hsh|
      next if handler.empty?

      # should_pop = handler[:has_one]
      query = handler[:query]
      clause = handler[:clause]

      reduced_handler = reduce_handler(handler, filters)
      # reduced_result = should_pop ? reduced_handler.pop : reduced_handler


      clause_or_query = (clause || query)
      
      if hsh[clause_or_query].is_a? Array
        hsh[clause_or_query] = 
          (hsh[clause_or_query] || []).push(reduced_handler)
      else
        hsh[clause_or_query] = 
          (hsh[clause_or_query] || {}).merge(reduced_handler)
      end
    end
  end

  def reduce_handler(handler, filters)
    query_type = handler[:query_type]
    send("build_#{query_type}_query", handler, filters)
  end
end