module ViewBacked
  class ColumnRails4 < Struct.new(:name, :default, :type)
    def to_active_record_column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s, default, cast_type
      )
    end

    private

    def cast_type
      {
        integer: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer,
        date: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date,
        decimal: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Decimal,
        string: ActiveRecord::Type::String
      }[type].new
    end
  end
end
