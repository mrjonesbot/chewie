require 'spec_helper'
require 'pry'

RSpec.describe EsBuilder do
  let!(:query) { "Art" }
  let!(:multimatch_fields) { %i[zipcode category_text community_area_text] }
  let!(:filters) do
    {
      active_school_years: 8,
      governances: ["Charter", "Alop"],
      network_id: [8, 2, 1],
      ages: { "gte": 20, "lte": 10, format: "mm/dd/yyyy" },
      discipline_ids: [1, 2, 3],
    }
  end

  let!(:service) do
    EsBuilder::Interface.new(query: "Art", filters: filters)
  end

  let(:build_governances_filter) do
    format = ->(value, adds) do
      "governance_#{value}_school_year_id_#{adds.first}"
    end

    service.filter(:governances,
      with: :terms, combine: [:active_school_years], format: format)
  end

  let(:build_ages_range_filter) do
    service.filter(:ages, with: :range)
  end

  let(:build_ages_range) do
    service.range(:ages, options: { boost: 3 })
  end

  let(:build_active_school_year_filter) do
    format = ->(value) do
      "school_year_id_#{value}_active_true"
    end

    service.filter(:active_school_years,
      with: :term, format: format)
  end

  let(:build_multimatch_must_compound) do
    fields = %i[zipcode category_text community_area_text]
    service.multimatch(with: fields, context: :compound)
  end

  let(:build_multimatch_should_compound) do
    fields = %i[zipcode category_text community_area_text]
    service.multimatch(with: fields, context: :compound, clause: :should)
  end

  # let(:build_or_filter) do
  #   service.and_or_filter(:discipline_ids, with: :terms, operator: :or)
  # end

  # let(:build_and_filter) do
  #   service.and_or_filter(:discipline_ids, with: :terms)
  # end

  let(:fuzzy_search_attribute) { :name }

  let(:build_fuzzy_compound_search) do
    options = { boost: 3 }
    service.fuzzy(fuzzy_search_attribute, context: :compound, options: options)
  end

  let(:build_range_compound_query) do
    options = { boost: 3 }
    service.range(:ages, context: :compound, options: options)
  end

  let(:build_fuzzy_search) do
    options = { boost: 3 }
    service.fuzzy(fuzzy_search_attribute, options: options)
  end

  let(:filter_queries) { service.filter_queries }
  let(:filter_query) { service.filter_queries.first }

  it 'puts the full output' do
    build_governances_filter
    build_active_school_year_filter
    build_fuzzy_compound_search
    build_fuzzy_search
    build_multimatch_must_compound
    build_ages_range_filter
    build_ages_range
    puts service.call
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

  describe '#filter' do
    context 'term with formatting' do
      before do
        build_active_school_year_filter
      end

      let(:value) { filter_query[:term][:active_school_years] }

      it 'adds a single query to the filter_queries collection' do
        expect(filter_queries.count).to eq 1
      end

      it 'sets a non array value for the :term clause' do
        expect(!value.is_a?(Array)).to be true
      end

      it 'sets a non hash value for the :term clause' do
        expect(!value.is_a?(Array)).to be true
      end

      it 'enforces formatting' do
        expect(value).to eq "school_year_id_8_active_true"
      end
    end

    context '#range' do
      before do
        build_ages_range_filter
      end

      let(:values) { filter_query[:range][:ages] }
      it 'adds a single query to the filter_queries collection' do
        expect(filter_queries.count).to eq 1
      end

      it 'set :range value is a hash' do
        expect(values.is_a?(Hash)).to be true
      end

      it 'sets gte value' do
        expect(values[:gte]).to eq 20
      end

      it 'sets lte value' do
        expect(values[:lte]).to eq 10
      end

      it 'sets format value' do
        expect(values[:format]).to eq "mm/dd/yyyy"
      end
    end

    context 'terms with combined formatting' do
      before do
        build_governances_filter
      end

      let(:filter_queries) { service.filter_queries }
      let(:filter_query) { filter_queries.first }
      let(:values) { filter_query[:terms][:governances] }

      it 'adds a single query to the filter_queries collection' do
        expect(filter_queries.count).to eq 1
      end

      it 'set :terms value is an array' do
        expect(values.is_a?(Array)).to be true
      end

      it 'sets multiple values for the :terms clause' do
        expect(values.count).to eq 2
      end

      it 'enforces formatting' do
        expect(values.first).to eq "governance_Charter_school_year_id_8"
      end
    end
  end

  describe '#multimatch' do
    context 'compound' do
      context 'must clause' do
        before do
          build_multimatch_must_compound
        end

        let(:must_queries) { service.must_queries }
        let(:multimatch_query) { must_queries.first[:multi_match] }
        let(:match_query) { multimatch_query[:query] }
        let(:fields) { multimatch_query[:fields] }

        it 'enforces field matching' do
          expect(fields).to eq multimatch_fields
        end

        it 'uses the correct query value' do
          expect(match_query).to eq query
        end
      end

      context 'should clause' do
        before do
          build_multimatch_should_compound
        end

        let(:should_queries) { service.should_queries }
        let(:multimatch_query) { should_queries.first[:multi_match] }
        let(:match_query) { multimatch_query[:query] }
        let(:fields) { multimatch_query[:fields] }

        it 'enforces field matching' do
          expect(fields).to eq multimatch_fields
        end

        it 'uses the correct query value' do
          expect(match_query).to eq query
        end
      end
    end
  end

  describe '#fuzzy' do
    context 'building compound queries' do
      before do
        build_fuzzy_compound_search
      end

      let(:must_queries) { service.must_queries }
      let(:fuzzy_query) { must_queries.first[:fuzzy] }
      let(:fuzzy_attribute) { fuzzy_query[fuzzy_search_attribute] }
      let(:value) { fuzzy_attribute[:value] }

      it 'should insert query in must_queries' do
        expect(must_queries.length).to eq 1
      end

      it 'includes option values' do
        expect(fuzzy_attribute.include?(:boost)).to be true
        expect(fuzzy_attribute[:boost]).to eq 3
      end

      it 'set the query value' do
        expect(value).to eq query
      end
    end

    context 'building term_level queries' do
      before do
        build_fuzzy_search
      end

      let(:term_level_queries) { service.term_level_queries }
      let(:fuzzy_query) { term_level_queries.first[:fuzzy] }
      let(:fuzzy_attribute) { fuzzy_query[fuzzy_search_attribute] }
      let(:value) { fuzzy_attribute[:value] }

      it 'should insert query in should_queries' do
        expect(term_level_queries.length).to eq 1
      end

      it 'includes option values' do
        expect(fuzzy_attribute.include?(:boost)).to be true
        expect(fuzzy_attribute[:boost]).to eq 3
      end

      it 'set the query value' do
        expect(value).to eq query
      end
    end
  end
end
