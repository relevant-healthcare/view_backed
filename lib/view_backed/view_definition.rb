class ViewDefinition
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def columns
    selections.map(&:column)
  end

  def scope
    selections.inject(from) do |acc, selection|
      acc.select("(#{selection.expression}) AS #{selection.column.name}")
    end
  end

  def string(name, expression = name.to_s)
    column(name, :string, expression)
  end

  def integer(name, expression = name.to_s)
    column(name, :integer, expression)
  end

  def date(name, expression = name.to_s)
    column(name, :date, expression)
  end

  def decimal(name, expression = name.to_s)
    column(name, :decimal, expression)
  end

  def column(name, data_type, expression = name.to_s)
    selections << Selection.new(
      new_column(name, nil, data_type_to_cast_type(data_type), data_type),
      expression
    )
  end

  def from(from = nil)
    @from ||= from
  end

  private

  def data_type_to_cast_type(data_type)
    {
      integer: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer,
      date: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date,
      decimal: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal,
      string: ActiveRecord::Type::String
    }[data_type].new
  end

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

  class Selection
    attr_reader :column

    def initialize(column, expression)
      @column = column
      @expression = expression
    end

    def expression
      @expression.try(:to_sql) || @expression
    end
  end
end
