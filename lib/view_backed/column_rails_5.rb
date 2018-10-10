module ViewBacked
  class ColumnRails5 < Struct.new(:name, :default, :type)
    def to_active_record_column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s, default, self
      )
    end
  end
end
