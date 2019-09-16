require_relative '../../lib/es_builder_toy'

RSpec.shared_context 'school search interface' do
  before(:context) do
    class SchoolSearch
      extend EsBuilderToy::Interface

      governances_format = lambda do |value, adds|
        "governance_#{value}_school_year_id_#{adds.first}"
      end

      active_school_years_format = lambda do |value|
        "school_year_id_#{value}_active_true"
      end

      fuzzy :name
      fuzzy :name, context: :bool, options: { clause: :must }

      filter_by :active_school_years, with: :term, 
                                      format: active_school_years_format
      filter_by :governances, with: :terms,
                              combine: [:active_school_years],
                              format: governances_format

      filter_by :ages, with: :range
    end
  end
end


# filters = {
#       active_school_years: 8,
#       governances: ["Charter", "Alop"],
#       network_id: [8, 2, 1],
#       ages: { "gte": 20, "lte": 10, format: "mm/dd/yyyy" },
#       discipline_ids: [1, 2, 3],
#     }

# filters = { governances: ["Charter", "Alop"], active_school_years: 8}
# ages: { "gte": 20, "lte": 10, format: "mm/dd/yyyy" }
# SchoolSearch.call(query: "", filters: filters, options: {})

# RSpec.shared_context 'user strong arm' do

#   # Movie, Actor Classes and serializers
#   before(:context) do
#     class UserStrongArm
#       extend StrongArms

#       ignore :created_at, :updated_at

#       permit :id
#       permit :name
#       permit :email, required: true
#       permit :public

#       many_nested :posts
#       one_nested :tag, format: false
#     end

#     class PostStrongArm
#       extend StrongArms

#       ignore :created_at, :updated_at

#       permit :id
#       permit :title, required: true
#       permit :_destroy

#       many_nested :comments
#     end

#     class CommentStrongArm
#       extend StrongArms

#       ignore :created_at, :updated_at

#       permit :id
#       permit :text, required: true
#       permit :_destroy
#     end

#     class FocusStrongArm
#       extend StrongArms

#       ignore :created_at, :updated_at

#       permit :id
#       permit :text, required: true
#       permit :_destroy
#     end

#     class TagStrongArm
#       extend StrongArms

#       ignore :created_at, :updated_at, :display_name

#       permit :id
#       permit :type
#       permit :name

#       one_nested :tag_group, format: false
#       one_nested :tag_category, format: false
#     end
#   end
# end
