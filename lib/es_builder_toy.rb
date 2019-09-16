require './lib/es_builder/version'
require 'active_support/all'
require 'pry'

# => {:from=>0,
#  :size=>10,
#  :query=>
#   {
#    :bool=>
#     {:must=>
#       [{:fuzzy=>{:name=>{:boost=>3, :value=>"Art"}}},
#        {:multi_match=>
#          {:fields=>[:zipcode, :category_text, :community_area_text],
#           :query=>"Art"}}],
#      :filter=>
#       [{:terms=>
#          {:governances=>
#            ["governance_Charter_school_year_id_8",
#             "governance_Alop_school_year_id_8"]}},
#        {:term=>{:active_school_years=>"school_year_id_8_active_true"}},
#        {:range=>{:ages=>{"gte"=>20, "lte"=>10, "format"=>"mm/dd/yyyy"}}}]}}}

# DSL
# compound queries
#   - boolean query
#     - must (clause)
#       - term (query)
#       - terms (query)
#     - should (clause)
#     - must_not (clause)
#     - filter (clause)
# full text queries
#   - match (query)
#   - multimatch (query)
# term level queries
#   - fuzzy (query)
#   - range (query)
#   - term (query)
#   - terms (query)
module EsBuilderToy
  module Interface
    def build(query: '', filters: {}, options: {})
      query_data = set_query_data(query, filters)
      bool_options = options[:bool] || {}

      match_all_query(options) if query_data[:filters].empty?

      context(:query, options) do
        query_context = reduce_handlers(data: query_data)
        bool_context = context(:bool, bool_options) do
          reduce_handlers(data: query_data, context: :bool)
        end

        query_context.merge(bool_context)
      end
    end

    def context(key, **options)
      options.merge(key => yield)
    end

    def set_query_data(query, filters)
      {
        filters: clean_filters(filters).merge(query: query)
      }
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

    def match_all_query(options)
      context(:query, options) do
        { match_all: {} }
      end
    end

    # compound query clauses
    def filter_by(attribute, with:, combine: [], format: nil)
      handler = { 
        attribute: attribute, 
        with: with,
        combine: combine, 
        format: format,
        query_type: :bool,
      }
      set_handler(context: :bool, query: :filter, handler: handler)
    end

    def fuzzy(attribute, context: :query, options: {})
      clause_or_query = (context == :query) ? :fuzzy : options[:clause]

      # TODO consider using a struct for handlers
      handler = { attribute: attribute, query_type: :term_level, has_one: true }
      set_handler(context: context, query: clause_or_query, handler: handler)
    end

    # leaf query clauses
    # def range(by, options: {})
    #   handle_options = {
    #     with: :range, combine: [], format: nil, options: options
    #   }

    #   set_handler(name: by, options: handle_options)
    # end

    def set_handler(context: :query, query:, handler: {})
      if handlers[context][query].present?
        handlers[context][query].push(handler)
      else
        handlers[context][query] = [handler]
      end
    end

    def handlers
      @handlers ||= {
        query: {},
        bool: {}
      }
    end

    def clean_filters(filters)
      filters.reject do |_, value|
        value.nil?
      end.with_indifferent_access
    end

    def build_term_level_query(conditions, filters={})
      attribute = conditions[:attribute]
      value = filters[attribute] || filters[:query]

      return {} if value.nil?
      return [] if [value].flatten.empty?

      context(attribute) do
        { value: value }
      end
    end

    # use at runtime
    def build_bool_query(conditions, filters={})
      # by, with, combine, format = conditions
      attribute = conditions[:attribute]

      _value = filters[attribute]
      # value_is_hash = _value.is_a?(Hash)

      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # values_present = -> { _value['values'] || [] }

      return {} if _value.nil?

      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # return {} if value_is_hash && values_present.call.empty?
      return [] if [_value].flatten.empty?

      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # _value = _value['values'] if value_is_hash

      format = conditions[:format]
      with = conditions[:with]
      combine = conditions[:combine]

      should_format = format.present?
      combined = fetch_combine_values(combine, filters)
      new_value =
        format_or_return_value(_value, combined, format, should_format)
      exposed_value = expose_or_return_value(new_value, with, should_format)

      context(with) do
        { attribute => exposed_value }
      end
    end

    def fetch_combine_values(keys, filters)
      keys.map { |key| filters[key] }
    end

    def format_or_return_value(value, combined, format, should_format)
      should_format ? format_values(value, combined, format) : value
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
end
