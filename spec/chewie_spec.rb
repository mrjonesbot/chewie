# frozen_string_literal: true

require 'pp'
require 'spec_helper'
require 'pry'

RSpec.describe Chewie do
  include_context 'school search interface'

  let!(:query) { "Art" }
  let!(:multimatch_fields) { %i[zipcode description] }
  let!(:filters) do
    {
      active_school_years: 8,
      governances: %w[Charter Alop],
      description: 'Supports arts and science programs',
      ages: { "gte": 20, "lte": 10, format: "mm/dd/yyyy" },
      zipcode: ['11111', '22222'],
      # network_id: [8, 2, 1],
      # discipline_ids: [1, 2, 3]
    }
  end

  let!(:service) do
    SchoolChewie
  end

  let!(:handlers) do
    service.handlers
  end

  let(:result) { service.build(query: "Art", filters: filters) }

  it 'puts the full output' do
    PP.pp(result, $>, 80) 
  end

  describe '#filter_by' do
    context 'term with formatting' do
      context 'active_school_years' do
        let(:handler) { handlers[:bool].first }
        let(:bool_context) { result[:query][:bool] }
        let(:filter_context) { bool_context[:filter] }
        let(:term) { filter_context.first }
        let(:term_query) { term[:term] }
        let(:expected_value) do
          {
            term: {
              active_school_years: "school_year_id_8_active_true"
            }
          }
        end

        it 'defines a handler' do
          expect(handler.present?).to be true
        end

        it 'sets a valid query under the :term clause' do
          expect(term).to eq expected_value
        end

        it 'sets a hash for the :term clause' do
          expect(term.is_a?(Hash)).to be true
        end

        it 'enforces formatting' do
          expect(term_query[:active_school_years]).
            to eq "school_year_id_8_active_true"
        end
      end
    end

    context 'terms with combined formatting' do
      let(:handler) { handlers[:bool].second }
      let(:output) { result[:query][:bool] }
      let(:filter_context) { output[:filter] }
      let(:terms) { filter_context.second }
      let(:governances) { terms[:terms][:governances] }
      let(:expected_value) do
        {
          terms: {
            governances: [
              "governance_Charter_school_year_id_8",
              "governance_Alop_school_year_id_8"
            ]
          }
        }
      end

      it 'defines a handler' do
        expect(handler.present?).to be true
      end

      it 'sets a valid query under the :terms clause' do
        expect(terms).to eq expected_value
      end

      it 'set :terms attribute is an array' do
        expect(governances.is_a?(Array)).to be true
      end

      it 'sets multiple values under the attribute for the :terms clause' do
        expect(governances.count).to eq 2
      end

      it 'enforces formatting' do
        expect(governances.first).
          to eq "governance_Charter_school_year_id_8"
      end
    end

    context 'range' do
      let(:handler) do 
        handlers[:bool].last
      end
      let(:output) { result[:query][:bool] }
      let(:filter) { output[:filter] }
      let(:range) { filter.last }
      let(:range_query) { range[:range][:ages] }
      let(:expected_value) do
        {
          range: {
            ages: {
              "gte" => 20,
              "lte" => 10,
              "format" => "mm/dd/yyyy"
            }
          }
        }
      end

      it 'defines a handler(s)' do
        expect(handler.present?).to be true
      end

      it 'sets a valid query under the :range clause' do
        expect(range).to eq expected_value
      end

      it 'sets gte value' do
        expect(range_query[:gte]).to eq 20
      end

      it 'sets lte value' do
        expect(range_query[:lte]).to eq 10
      end

      it 'sets format value' do
        expect(range_query[:format]).to eq "mm/dd/yyyy"
      end
    end
  end

  describe '#match' do
    let(:handler) do
      handlers[:query].third
    end
    let(:output) { result[:query] }
    let(:match) { output[:match] }
    let(:match_query) { match[:description] }
    let(:expected_value) do
      {
        description: {
          query: 'Supports arts and science programs',
          boost: 0.5
        }
      }
    end

    it 'defines a handler(s)' do
      # binding.pry
      expect(handler.present?).to be true
    end

    it 'sets a valid query under the :must clause' do
      expect(match).to eq expected_value
    end

    it 'sets a message value' do
      expect(match_query[:query]).to eq 'Supports arts and science programs'
    end

    it 'sets option values' do
      expect(match_query[:boost]).to eq 0.5
    end
  end

  describe '#multimatch' do
    let(:handler) do
      handlers[:query].third
    end
    let(:output) { result[:query] }
    let(:multimatch) { output[:multimatch] }
    let(:expected_value) do
      { :fields=>[:description], :query=>"Art", :boost=>0.5 }
    end

    it 'defines a handler(s)' do
      expect(handler.present?).to be true
    end

    it 'sets a valid query' do
      expect(multimatch).to eq expected_value
    end

    it 'sets a fields value' do
      expect(multimatch[:fields]).to eq [:description]
    end

    it 'sets a query value' do
      expect(multimatch[:query]).to eq 'Art'
    end

    it 'sets option values' do
      expect(multimatch[:boost]).to eq 0.5
    end

    context 'when building a compound query' do
      let(:multimatch) { output[:bool][:must].second }
      let(:multimatch_query) { multimatch[:multimatch] }

      it 'sets a valid query under the must clause' do
        expect(multimatch_query).to eq expected_value
      end
    end
  end

  describe '#range' do
    let(:handler) do
      handlers[:query].second
    end
    let(:output) { result[:query] }
    let(:range) { output[:range] }
    let(:range_query) { range[:ages] }
    let(:expected_value) do
      {
        ages: {
          "gte" => 20,
          "lte" => 10,
          "format" => "mm/dd/yyyy",
          "boost" => 2
        }
      }
    end

    it 'defines a handler(s)' do
      expect(handler.present?).to be true
    end

    it 'sets a valid query under the :range clause' do
      expect(range).to eq expected_value
    end

    it 'sets gte value' do
      expect(range_query[:gte]).to eq 20
    end

    it 'sets lte value' do
      expect(range_query[:lte]).to eq 10
    end

    it 'sets format value' do
      expect(range_query[:format]).to eq "mm/dd/yyyy"
    end

    it 'sets option values' do
      expect(range_query[:boost]).to eq 2
    end
  end

  describe '#fuzzy' do
    context 'building compound must queries' do
      let(:handler) { handlers[:bool].first }
      let(:output) { result[:query] }
      let(:must_clause) { output[:bool][:must] }
      let(:fuzzy_query) do
        if must_clause.is_a? Array
          must_clause.first[:fuzzy][:name]
        else
          must_clause[:fuzzy][:name]
        end
      end
      let(:expected_result) do
        {
          fuzzy: {
            name: {
              value: "Art",
              boost: 3
            },
          }
        }
      end

      it 'defines a handler' do
        expect(handler.present?).to be true
      end

      it 'includes option values' do
        expect(fuzzy_query.include?(:boost)).to be true
        expect(fuzzy_query[:boost]).to eq 3
      end

      it 'sets a valid fuzzy query under the :must clause' do
        result = must_clause.is_a?(Array) ? must_clause.first : must_clause
        expect(result).to eq expected_result 
      end

      it 'set the query value' do
        expect(fuzzy_query[:value]).to eq query
      end 
    end

    context 'building leaf queries' do
      let(:handler) do 
        handlers[:query].first
      end
      let(:output) { result[:query] }
      let(:fuzzy) { output[:fuzzy] }
      let(:fuzzy_query) { fuzzy[:name] }
      let(:expected_value) do
        {
          name: {
            value: "Art",
            boost: 3
          },
        }
      end

      it 'defines a handler' do
        expect(handler.present?).to be true
      end

      it 'sets a valid query under the :fuzzy clause' do
        expect(fuzzy).to eq expected_value
      end

      it 'includes option values' do
        expect(fuzzy_query.include?(:boost)).to be true
        expect(fuzzy_query[:boost]).to eq 3
      end

      it 'set the query value' do
        expect(fuzzy_query[:value]).to eq query
      end
    end
  end
end
