require './lib/chewie/version'
require 'chewie/utils'
require 'chewie/interface/bool'
require 'chewie/interface/term_level'
require 'chewie/interface/full_text'
require 'chewie/handler/reduced'
require 'active_support/all'
require 'pry'

module Chewie
  include Chewie::Interface::Bool
  include Chewie::Interface::TermLevel
  include Chewie::Interface::FullText

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
