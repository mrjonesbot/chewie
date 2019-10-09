require './lib/es_builder/version'
require 'es_builder/utils'
require 'es_builder/handlers'
require 'es_builder/query_builders'
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
    include Utils
    include Handlers
    include QueryBuilders
  
    # TODO: solidify schema for handlers with structs

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

    def match_all_query(options)
      context(:query, options) do
        { match_all: {} }
      end
    end

    # BOOL QUERIES
    # * tested
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

    
    # TERM LEVEL QUERIES
    # * tested
    def fuzzy(attribute, context: :query, options: {})
      clause_or_query = (context == :query) ? :fuzzy : options[:clause]

      # TODO consider using a struct for handlers
      handler = { attribute: attribute, query_type: :term_level, has_one: true }
      set_handler(context: context, query: clause_or_query, handler: handler)
    end

    # * untested
    def range(by, options: {})
      handle_options = {
        with: :range, combine: [], format: nil, options: options
      }

      set_handler(name: by, options: handle_options)
    end
  end
end
