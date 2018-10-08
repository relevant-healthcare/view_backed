class ViewDefinition
  attr_reader :view_name

  def initialize(view_name)
    @view_name = view_name
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
      new_column(name, nil, data_type),
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

  def new_column(name, default, type)
    if ActiveRecord::Type.respond_to?(:registry)
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s,
        default,
        get_sql_type_metadata(type),
        true,
        view_name
      )
    else
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s,
        default,
        data_type_to_cast_type(type),
        ActiveRecord::Base.connection.type_to_sql(type)
      )
    end
  end

  def get_sql_type_metadata(type)
    cast_type = ActiveRecord::Type.registry.lookup(type)
    sql_type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
      sql_type: ActiveRecord::Base.connection.type_to_sql(type),
      type: cast_type.type,
      limit: cast_type.limit,
      precision: cast_type.precision,
      scale: cast_type.scale
    )
  end

  # def new_column_with_cast_type(name, default, type)
  #   ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
  #     name.to_s,
  #     default,
  #     data_type_to_cast_type(type),
  #     ActiveRecord::Base.connection.type_to_sql(type)
  #   )
  # end

  # def new_column_from_field(table_name, field)
  #   column_name, type, default, notnull, oid, fmod, collation, comment = field
  #   type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
  #   default_value = extract_value_from_default(default)
  #   default_function = extract_default_function(default_value, default)

  #   PostgreSQLColumn.new(
  #     column_name,
  #     default_value,
  #     type_metadata,
  #     !notnull,
  #     table_name,
  #     default_function,
  #     collation,
  #     comment: comment.presence,
  #     max_identifier_length: max_identifier_length
  #   )
  # end

  # def fetch_type_metadata(column_name, sql_type, oid, fmod)
  #   cast_type = get_oid_type(oid, fmod, column_name, sql_type)
  #   simple_type = SqlTypeMetadata.new(
  #     sql_type: sql_type,
  #     type: cast_type.type,
  #     limit: cast_type.limit,
  #     precision: cast_type.precision,
  #     scale: cast_type.scale,
  #   )
  #   PostgreSQLTypeMetadata.new(simple_type, oid: oid, fmod: fmod)
  # end
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
