require 'active_support/inflector'

require_relative 'sql_object'
require_relative 'searchable'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || :"#{name.to_s}_id"
    @class_name = options[:class_name] || name.to_s.camelcase
    @primary_key = options[:primary_key] || :id
    # debugger
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.underscore.singularize}_id".to_sym


    @class_name = options[:class_name] ||   name.to_s.camelcase.singularize
    @primary_key = options[:primary_key] || :id

  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) do
      belongs_options = self.class.assoc_options[name]
      foreign_key = send(belongs_options.foreign_key)
      model_class = belongs_options.class_name

      model_class.constantize.where(belongs_options.primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})

    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      has_many_options = self.class.assoc_options[name]
      primary_key = send(has_many_options.primary_key)

      model_class = has_many_options.class_name

      model_class.constantize.where(has_many_options.foreign_key => primary_key)
    end
    # has_many_options.model_class.where(has_many_options.primary_key => has_many_options.foreign_key)
  end


  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one_through(name, through_name, source_name)


    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_options_table = through_options.table_name
      through_options_foreign_key = through_options.foreign_key
      through_options_primary_key = through_options.primary_key

      source_options_table = source_options.table_name
      source_options_foreign_key = source_options.foreign_key
      source_options_primary_key = source_options.primary_key



      search_key = self.send(through_options_foreign_key)
      has_one_results = DBConnection.execute(<<-SQL, search_key)
        SELECT
          #{source_options_table}.*
        FROM
          #{through_options_table}
        JOIN
          #{source_options_table}
        ON
          #{source_options_table}.#{source_options_primary_key} = #{through_options_table}.#{source_options_foreign_key}

        WHERE
          #{through_options_table}.#{through_options_primary_key} = INTERPOLATOR_MARK

      SQL

      source_options.model_class.parse_all(has_one_results).first
    end
  end

end

class SQLObject
  extend Associatable
end
