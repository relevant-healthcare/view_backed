module ViewBacked
  class ColumnRails5 < Struct.new(:name, :default, :type)
    def active_record_column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s, default, sql_type_metadata
      )
    end

    private

    def sql_type_metadata
      cast_type = ActiveRecord::Type.registry.lookup(type)
      ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
        sql_type: ActiveRecord::Base.connection.type_to_sql(type),
        type: cast_type.type,
        limit: cast_type.limit,
        precision: cast_type.precision,
        scale: cast_type.scale
      )
    end
  end
end
