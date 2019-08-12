require "./lib/es_builder/version"
require "active_support/all"

module EsBuilder
  include ActiveSupport

  QUERY_CLAUSES = %i[term_level full_text].freeze
  BOOL_CLAUSES = %i[must filter should must_not].freeze

  class Error < StandardError; end
  class Interface
    attr_reader :from,
                :size,
                :sort,
                :query,
                :must_queries,
                :filter_queries,
                :should_queries,
                :must_not_queries,
                :term_level_queries,
                :full_text_queries,
                :highlight_queries
                # :match_queries,
                # :range_queries

    

    def initialize(query: "", filters: {}, options: {})
      @query = query
      @sort = options.fetch(:sort, '')
      @from = options.fetch(:from, 0)
      @size = options.fetch(:size, 10)
      @paginate = options.fetch(:paginate, true)
      @_filters = filters
      # bool queries
      @must_queries = []
      @filter_queries = []
      @should_queries = []
      @must_not_queries = []

      # term queries
      # @match_queries = []
      # @range_queries = []

      @term_level_queries = []
      # does not work as expected
      @full_text_queries = []
      @highlight_queries = []
    end

    def call
      # return {} if clean_filters.empty?
      options = { from: from, size: size, sort: sort_query }.compact
      highlight = highlight_queries.first || {}
      if clean_filters.empty?
        context(:query, options) do
          { match_all: {} }
        end
      else
        context(:query, options) do
          query_context = build_context_with_clauses(:query)
          bool_context = build_context_with_clauses(:bool)
          query_context[:query].merge(bool_context)
        end.merge(highlight)
      end
    end

    def highlight(fields: [], options: {})
      return self if fields.empty?

      query = { highlight: { fields: fields }.merge(options) }
      highlight_queries.push(query)

      self
    end

    # TODO: needs validation
    # def and_or_filter(by, with:, combine: [], format: nil, operator: 'and')
    #   _value = clean_filters[by]
    #   op = _value.is_a?(Hash) ? _value['operator'] : operator
    #   if op == 'or'
    #     should(by, with: with, combine: combine, format: format)
    #   else
    #     filter(by, with: with, combine: combine, format: format)
    #   end
    #   self
    # end

    # BOOL COMPOUND CLAUSES
    def filter(by, with:, combine: [], format: nil)
      filter_query = build_term_query(by, with, combine, format)
      filter_queries.push(filter_query) unless filter_query.empty?
      self
    end

    def should(by, with:, combine: [], format: nil)
      should_query = build_term_query(by, with, combine, format)
      should_queries.push(should_query) unless should_query.empty?
      self
    end

    def must(by, with:, combine: [], format: nil)
      must_query = build_term_query(by, with, combine, format)
      must_queries.push(must_query) unless must_query.empty?
      self
    end

    def must_not(by, with:, combine: [], format: nil)
      must_not_query = build_term_query(by, with, combine, format)
      must_not_queries.push(must_not_query) unless must_not_query.empty?
      self
    end

    # TERM_LEVEL CLAUSES
    def fuzzy(by, context: :query, options: {})
      return self if query.nil? || query.empty?

      fuzzy_query = context(:fuzzy) do
        { by => options.merge(value: query) }
      end

      if context == :compound
        must_queries.push(fuzzy_query)
      else
        term_level_queries.push(fuzzy_query)
      end

      self
    end

    def range(by, options: {})
      return self if by.nil? || by.empty?

      build_term_query(by, :range, [], nil).merge(options)
    end

    # FULL_TEXT CLAUSES
    def multimatch(with: [], context: :query, clause: :must, options: {})
      # raise 'bad fields' unless with.all? {|value| !value.is_a?(Hash) }
      return self if query.nil? || query.empty?

      multimatch_query = context(:multi_match) do
        { fields: with, query: query }.merge(options)
      end

      if context == :compound
        send("#{clause}_queries").push(multimatch_query)
      else
        full_text_queries.push(multimatch_query)
      end

      self
    end

    private

    attr_reader :_filters

    def context(key, **options)
      options.merge(key => yield)
    end

    def build_context_with_clauses(context)
      return {} unless send("any_#{context}_clauses?")

      new_hash = {}
      clause_const = fetch_clause_const(context)

      context(context) do
        clause_const.each do |clause|
          queries = send("#{clause}_queries")

          if queries.any?
            # NOTE: does not appropriately set key under query context
            new_hash[clause] = queries
          end
        end
        new_hash
      end
    end

    def fetch_clause_const(context)
      "EsBuilder::#{context.upcase}_CLAUSES".constantize
    end

    def any_query_clauses?
      @any_query_clauses ||= QUERY_CLAUSES.any? do |clause|
        send("#{clause}_queries")
      end
    end

    def any_bool_clauses?
      @any_bool_clauses ||= BOOL_CLAUSES.any? do |clause|
        send("#{clause}_queries")
      end
    end

    def build_term_query(by, with, combine, format)
      _value = clean_filters[by]
      # value_is_hash = _value.is_a?(Hash)

      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # values_present = -> { _value['values'] || [] }

      return {} if _value.nil?

      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # return {} if value_is_hash && values_present.call.empty?
      return [] if [_value].flatten.empty?


      # NOTE: supports #and_or_filter, but conflicts with #range queries
      # _value = _value['values'] if value_is_hash

      should_format = format.present?
      combined = fetch_combine_values(combine)
      new_value = format_or_return_value(_value, combined, format, should_format)
      exposed_value = expose_or_return_value(new_value, with, should_format)
      context(with) do
        { by => exposed_value }
      end
    end

    def clean_filters
      @clean_filters ||= _filters.reject do |_, value|
        value.nil?
      end.with_indifferent_access
    end

    def fetch_combine_values(keys)
      keys.map { |key| clean_filters[key] }
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

    def sort_query
      if sort.present?
        sort_hash = JSON.parse(sort)
        [sort_hash]
      end
    end
  end
end
