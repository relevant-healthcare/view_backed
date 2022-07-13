module ViewBacked
  class ColumnRails5Or6 < Struct.new(:name, :default, :type)
    def to_active_record_column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s, default, self
      )
    end

    if Rails.version.match(/^6.1/)
      def deduplicate
        self
      end
    end
  end
end
