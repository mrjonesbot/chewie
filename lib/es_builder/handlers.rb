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

    # binding.pry
  #   [{:query=>:filter, :clause=>:must, :attribute=>:name, :query_type=>:term_level, :has_one=>true},
  #  {:query=>:filter,
  #   :attribute=>:active_school_years,
  #   :with=>:term,
  #   :combine=>[],
  #   :format=>#<Proc:0x00007fc734bee350@/Users/nathanjones/apps/es_builder/spec/contexts/school_search.rb:12 (lambda)>,
  #   :query_type=>:bool},]
    # if context == :bool
    #   binding.pry
    # end
    context_handlers.each.with_object({}) do |handler, hsh|
      next if handler.empty?

      should_pop = handler[:has_one]
      query = handler[:query]
      # should_pop = context == :query
      # if context == :bool
      #   binding.pry
      # end
      reduced_handler = [reduce_handler(handler, filters)]
      reduced_result = should_pop ? reduced_handler.pop : reduced_handler

      # if context == :bool
      #   puts reduced_handler
      #   binding.pry
      # end

      if reduced_result.is_a? Array
        hsh[query] = (hsh[query] || []).push(reduced_result).flatten
      else
        hsh[query] = (hsh[query] || {}).merge(reduced_result)
      end
    end
  end

  def reduce_handler(handler, filters)
    # handler.map do |handle|
      query_type = handler[:query_type]
      send("build_#{query_type}_query", handler, filters)
    # end
  end
end