module QueryBuilders
  def build_term_level_query(handler, filters={})
    attribute = handler[:attribute]
    value = filters[attribute] || filters[:query]

    return {} if value.nil?
    return [] if [value].flatten.empty?

    context(attribute) do
      { value: value }
    end
  end

  def build_bool_query(handler, filters={})
    attribute = handler[:attribute]
    _value = filters[attribute]

    return {} if _value.nil?
    return [] if [_value].flatten.empty?

    format = handler[:format]
    with = handler[:with]
    combine = handler[:combine]

    should_format = format.present?
    combined = fetch_combine_values(combine, filters)
    new_value =
      format_or_return_value(_value, combined, format, should_format)
    exposed_value = expose_or_return_value(new_value, with, should_format)

    context(with) do
      { attribute => exposed_value }
    end
  end
end