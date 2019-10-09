module Utils
  def context(key, **options)
    options.merge(key => yield)
  end

  def set_query_data(query, filters)
    {
      filters: clean_filters(filters).merge(query: query)
    }
  end

  def clean_filters(filters)
    filters.reject do |_, value|
      value.nil?
    end.with_indifferent_access
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