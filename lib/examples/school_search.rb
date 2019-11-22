require_relative '../es_builder'

class SchoolSearch
  extend EsBuilder::Interface

  governances_format = lambda do |value, adds|
    "governance_#{value}_school_year_id_#{adds.first}"
  end

  fuzzy :name
  filter_by :active_school_years, with: :term
  filter_by :governances, with: :terms,
                          combine: [:active_school_years],
                          format: governances_format
  filter_by :ages, with: :range
end
