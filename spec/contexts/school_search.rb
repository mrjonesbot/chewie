require_relative '../../lib/es_builder'

RSpec.shared_context 'school search interface' do
  before(:context) do
    class SchoolSearch
      extend EsBuilder

      governances_format = lambda do |value, adds|
        "governance_#{value}_school_year_id_#{adds.first}"
      end

      active_school_years_format = lambda do |value|
        "school_year_id_#{value}_active_true"
      end
      
      fuzzy :name, options: { boost: 3 }
      fuzzy :name, context: :bool, clause: :must, options: { boost: 3 }

      range :ages, options: { boost: 2 }

      match :description, options: { boost: 0.5 }
      multimatch with: [:description], options: { boost: 0.5 }
      multimatch with: [:description], 
        context: :bool, clause: :must, options: { boost: 0.5 }

      term :name, options: { boost: 1 }
      terms :governances, options: { boost: 1 }

      filter_by :active_school_years, 
        with: :term, format: active_school_years_format

      filter_by :governances, 
        with: :terms, 
        combine: [:active_school_years], 
        format: governances_format

      filter_by :ages, with: :range
    end
  end
end
