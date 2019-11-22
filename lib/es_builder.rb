require './lib/es_builder/version'
require 'es_builder/utils'
require 'es_builder/interface/bool'
require 'es_builder/interface/term_level'
require 'es_builder/interface/full_text'
require 'es_builder/handler/reduced'
require 'active_support/all'
require 'pry'

module EsBuilder
  include EsBuilder::Interface::Bool
  include EsBuilder::Interface::TermLevel
  include EsBuilder::Interface::FullText

  def handlers
    @handlers ||= {
      query: [],
      bool: []
    }
  end

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

  private

  include Utils

  def match_all_query(options)
    context(:query, options) do
      { match_all: {} }
    end
  end
end
