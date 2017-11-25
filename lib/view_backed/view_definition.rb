class ViewBacked::ViewDefinition
  attr_reader :name

  Selection = Struct.new(:column, :expression)

  def initialize(name)
    @name = name
  end

  def columns
    selections.map(&:column)
  end

  def scope
    selections.inject(from) do |acc, selection|
      acc.select("#{selection.expression} AS #{selection.column.name}")
    end
  end

  def string(name, expression = name.to_s)
    selections << Selection.new(
      new_column(name, nil, ActiveRecord::Type::String.new, :string),
      expression
    )
  end

  def integer(name, expression = name.to_s)
    selections << Selection.new(
      new_column(name, nil, ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new, :integer),
      expression
    )
  end

  def date(name, expression = name.to_s)
    selections << Selection.new(
      new_column(name, nil, ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date.new, :date),
      expression
    )
  end

  def from(from = nil)
    @from ||= from
  end

  private

  def new_column(name, default, cast_type, sql_type)
    ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
      name.to_s,
      default,
      cast_type,
      ActiveRecord::Base.connection.type_to_sql(sql_type)
    )
  end

  def selections
    @selections ||= []
  end
end
