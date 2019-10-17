# frozen_string_literal: true

require 'pp'
require 'spec_helper'
require 'pry'

RSpec.describe EsBuilderToy do
  include_context 'school search interface'

  let!(:query) { "Art" }
  let!(:multimatch_fields) { %i[zipcode category_text community_area_text] }
  let!(:filters) do
    {
      active_school_years: 8,
      governances: %w[Charter Alop],
      # network_id: [8, 2, 1],
      ages: { "gte": 20, "lte": 10, format: "mm/dd/yyyy" },
      # discipline_ids: [1, 2, 3]
    }
  end

  let!(:service) do
    SchoolSearch
  end

  let!(:handlers) do
    service.handlers
  end

  let(:result) { service.build(query: "Art", filters: filters) }

  it 'puts the full output' do
    PP.pp(result, $>, 80) 
  end

  # describe '.and_or_filter' do
  #   context 'or with terms' do
  #     before do
  #       build_or_filter
  #     end

  #     let(:should_queries) { service.should_queries }
  #     let(:should_query) { should_queries.first }
  #     let(:value) { should_query[:terms][:discipline_ids] }

  #     it 'adds a single query to the should_queries collection' do
  #       expect(should_queries.length).to eq 1
  #     end

  #     it 'sets discipline_ids under terms' do
  #       expect(should_query[:terms].key?(:discipline_ids)).to be true
  #     end

  #     it 'sets an array under discipline_ids' do
  #       expect(value.is_a?(Array)).to be true
  #     end
  #   end
  # end

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

  # describe '#multimatch' do
  #   context 'compound' do
  #     context 'must clause' do
  #       before do
  #         build_multimatch_must_compound
  #       end

  #       let(:must_queries) { service.must_queries }
  #       let(:multimatch_query) { must_queries.first[:multi_match] }
  #       let(:match_query) { multimatch_query[:query] }
  #       let(:fields) { multimatch_query[:fields] }

  #       it 'enforces field matching' do
  #         expect(fields).to eq multimatch_fields
  #       end

  #       it 'uses the correct query value' do
  #         expect(match_query).to eq query
  #       end
  #     end

  #     context 'should clause' do
  #       before do
  #         build_multimatch_should_compound
  #       end

  #       let(:should_queries) { service.should_queries }
  #       let(:multimatch_query) { should_queries.first[:multi_match] }
  #       let(:match_query) { multimatch_query[:query] }
  #       let(:fields) { multimatch_query[:fields] }

  #       it 'enforces field matching' do
  #         expect(fields).to eq multimatch_fields
  #       end

  #       it 'uses the correct query value' do
  #         expect(match_query).to eq query
  #       end
  #     end
  #   end
  # end

  describe '#fuzzy' do
    context 'building compound must queries' do
      let(:handler) { handlers[:bool].first }
      let(:output) { result[:query] }
      let(:must_clause) { output[:bool][:must] }
      let(:expected_result) do
        {
          fuzzy: {
            name: {
              value: "Art"
            },
            boost: 3
          }
        }
      end


      it 'defines a handler' do
        expect(handler.present?).to be true
      end

      # it 'includes option values' do
      #   expect(fuzzy_attribute.include?(:boost)).to be true
      #   expect(fuzzy_attribute[:boost]).to eq 3
      # end

      it 'sets a valid fuzzy query under the :must clause' do
        expect(must_clause).to eq expected_result 
      end

      # it 'set the query value' do
      #   expect(value).to eq query
      # end 
    end

    context 'building leaf queries' do
      let(:handler) do 
        handlers[:query].first
      end
      let(:output) { result[:query] }
      let(:fuzzy) { output[:fuzzy] }
      # let(:range) { filter.third }
      # let(:range_clause) { range[:range][:ages] }
      let(:expected_value) do
        {
          name: {
            value: "Art"
          },
          boost: 3
        }
      end

      it 'defines a handler' do
        expect(handler.present?).to be true
      end

      it 'sets a valid query under the :fuzzy clause' do
        expect(fuzzy).to eq expected_value
      end

      it 'includes option values' do
        # binding.pry
        expect(fuzzy.include?(:boost)).to be true
        expect(fuzzy[:boost]).to eq 3
      end

      # it 'set the query value' do
      #   expect(value).to eq query
      # end
    end
  end
end
