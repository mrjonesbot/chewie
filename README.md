# Chewie

A declarative interface for building Elasticsearch queries.

Building valid Elasticsearch queries by hand is difficult, especially as search criteria and logic become more complex.

Chewie aims to reduce the cognitive complexity of building queries, so you can focus on the search experience instead of grappling Elasticsearch syntax.

NOTE: Chewie currently supports Elasticsearch 7.x.

## Contents

* [Installation](#installation)
* [Usage](#usage)
* [Filtering by Associations](#filtering-by-associations)
   * [Format](#format)
   * [Combine](#combine)
* [Supported Queries (Documentation)](#supported-queries)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chewie'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chewie

## Usage

Define a `Chewie` class:

```ruby
# app/chewies/school_chewie.rb

class SchoolChewie
  extend Chewie

  term :name
  range :age
  match :description

  filter_by :governances, with: :terms 
end
```

Pass filter parameters to the `#build` method:

```ruby
# app/**/*.rb

params = {
  query: "Park School"
  filters: {
    age: { 'gte': 20, 'lte': 10 },
    governances: ['Charter', 'Alop']
  }
}

query = params[:query]
filters = params[:filters]

query = SchoolChewie.build(query: query, filters: filters)

puts query
# =>
#	{
# 	query: {
# 		term: { 
# 			name: { value: 'Park School' }
# 		},
# 		range: { 
# 			age: { 'gte': 20, 'lte': 10 }
# 		},
# 		match: {
# 			message: { query: 'Park School' }
# 		},
# 		bool: {
# 			filter: {
# 				terms: {
# 					governances: [ 'Charter', 'Alop' ]
# 				}
# 			}
# 		}
# 	}
# }
```

Chewie expects incoming parameter attributes to match the attributes defined in your Chewie class, in order to pull the correct value and build the query.

```ruby
# definition
filter_by :governances, with: :terms

# parameters
{ governances: ['ALOP'] }

# output
{ filter: { terms: { governances: ['ALOP'] } }
```

Some queries simply take a string value, which is pulled from `:query`.

`:query` is typically a user search value (search bar).

```ruby
# definition
term :name

# parameters
{ query: 'A search value' }

# output
{ query: { term: { name: { value: 'A search value' } } } }
```

## Filtering by Associations

Depending on how you build your index, some fields might store values from multiple tables.

A simple case is if you'd like to filter records through an association.

```ruby
class School
  has_many :school_disciplines
  has_many :disciplines, through: :school_disciplines
end

class Discipline
  has_many :school_disciplines
  has_many :schools, through: :school_disciplines
end

class SchoolDiscipline
  belongs_to :school
  belongs_to :discipline
end
```

We can imagine a search engine that helps users find schools in their area and allow them to filter schools by various criteria. 

Some schools might offer discipline specific programs, therefore a school will have many disciplines. 

Disciplines is a non-user populated collection that schools can associate with in the application.

In the search UI, we might provide a `disciplines` filter and allow users to filter by disciplines via dropdown.

We provide the search UI with `ids` of disciplines we'd like to filter by.

```json
{
  filters: {
    disciplines: [1, 2, 3, 4]
  }
}
```

The idex consists of school records, therefore we won't have access to every discipline each school is associated to by default.

Instead, we need to define custom index attributes for school records to capture those relationships.

We can do that by defining model methods on `School` that collects associated id values and returns a collection of strings to be indexed.

```ruby
class School
  def disciplines_index
    discipline_ids = disciplines.pluck(:id)
    discipline_ids.map do |discipline_id|
      "discipline_#{discipline_id}"
    end
  end

  # Method Elasticsearch can use to populate the index
  def search_data
    {
      name: name,
      disciplines: disciplines_index
    }
  end
end
```

When Elasticsearch indexes `School` records, each record will now have knowledge of which disciplines it is associated to.

```json
  { 
    name: 'Park School',
    disciplines: [
      "discipline_1",
      "discipline_2",
      "discipline_3"
    ]
  }
```

### Format
At this point, the index is ready to return associated `School` records when given a collection of `Discipline` ids. 

The caveat is the stored values of `:disciplines` is in a format that contains both the `School` and `Discipline` id.

We'll need to do a little extra work at search time to ensure the `id` filter values are transformed into the appropriate string format.

To address this, `bool` query methods have a `:format` option that takes a lambda and exposes attribute values given.

```ruby
class SchoolChewie
  disciplines_format = lambda do |id|
    "discipline_#{id}"
  end

  filter_by :disciplines, with: :terms, format: disciplines_format
end

params = {
  query: '',
  filters: {
    disciplines: [1, 4]
  }
}

result = SchoolChewie.build(query: params[:query], filters: params[:filters])

puts result
# =>
# {
# 	query: { 
# 		bool: { 
# 			filter: { 
# 				terms: { 
# 					disciplines: [
# 						"discipline_1",
# 						"discipline_4",
# 					]
# 				}
# 			}
# 		}
# 	}
# }
```

Now that the query for `disciplines` matches values stored in the index, Elasticsearch will find `School` records where `disciplines` match to either `"discipline_1"` or `"discipline_4"`; allowing us to find schools by their associated disciplines.

### Combine

Sometimes there are additional criteria we'd like to leverage when filtering against associated records.

Continuing with the previous example, let's say we want to filter schools by disciplines where the discipline programs are `"active"`.

`"active"` might be a boolean attribute found on `SchoolDiscipline`.

We can re-write `#discipline_index` to pull the discipline `id` and `active` attributes from `SchoolDiscipline` join records.

```ruby
class School
  def disciplines_index
    school_disciplines.map do |school_discipline|
      discipline_id = school_discipline.id
      active = school_discipline.active

      "discipline_#{discipline_id}_active_#{active}"
    end
  end

  # Method Elasticsearch can use to populate the index
  def search_data
    {
      name: name,
      disciplines: disciplines_index
    }
  end
end
```

Which changes the index to:

```json
  { 
    name: 'Park School',
    disciplines: [
      "discipline_1_active_true",
      "discipline_2_active_false",
      "discipline_3_active_false"
    ]
  }
```

We can now imagine there is a `active` toggle in the search UI, which expands the filter parameters.

```ruby
params = {
  query: '',
  filters: {
    disciplines: [1, 4],
    active: true
  }
}
```

At search time we not only need to format with the `disciplines` collection, but combine those values with the `active` attribute.

Let's update `SchoolChewie` to take this new criteria into account.

```ruby
class SchoolChewie
  disciplines_format = lambda do |id, combine|
    "discipline_#{id}_active_#{combine.first}"
  end

  filter_by :disciplines, with: :terms, combine: [:active], format: disciplines_format
end
```

`:combine` takes a collection of attribute symbols, which Chewie uses to access and pass parameter values to the format lambda at search time; the value collection is exposed as the second argument in the lambda block.

The order of the values matches the order defined in the method call.

```ruby
combine: [:active, :governances, :age]

lambda do |id, combine|
  combine[0] #=> :active value
  combine[1] #=> :governances value
  combine[2] #=> :age value
end
```

The new output:

```ruby
result = SchoolChewie.build(query: params[:query], filters: params[:filters])

puts result
# =>
# {
# 	query: { 
# 		bool: { 
# 			filter: { 
# 				terms: { 
# 					disciplines: [
# 						"discipline_1_active_true",
# 						"discipline_4_active_true",
# 					]
# 				}
# 			}
# 		}
# 	}
# }
```

## Supported Queries
### [Compound Queries](https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html)
#### [Bool](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html)

* [filter (#filter_by)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/Bool)
* [should (#should_include)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/Bool)
* [must (#must_include)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/Bool)
* [must_not (#must_not_include)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/Bool)

### [Term Level Queries](https://www.elastic.co/guide/en/elasticsearch/reference/current/term-level-queries.html)

* [term (#term)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/TermLevel)
* [terms (#terms)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/TermLevel)
* [range (#range)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/TermLevel)
* [fuzzy (#fuzzy)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/TermLevel)

### [Full Text Queries](https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html)

* [match (#match)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/FullText)
* [multi-match (#multimatch)](https://www.rubydoc.info/gems/chewie/0.2.2/Chewie/Interface/FullText)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/chewie. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Chewie project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/chewie/blob/master/CODE_OF_CONDUCT.md).
