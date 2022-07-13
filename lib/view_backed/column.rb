module ViewBacked
  class Column < Struct.new(:name, :default, :type)
    def to_active_record_column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
        name.to_s, default, self
      )
    end

    # https://github.com/rails/rails/pull/35891
    # Rails 6.1 added deduplication of AR schema cache structures to save memory
    # when these structures are identical (i.e. same column names and types).
    # The below code avoids deduplication, but in theory, we could add it by
    # reimplementing ActiveRecord::ConnectionAdapters::Deduplicable.
    if Rails.version.match(/^6.1/)
      def deduplicate
        self
      end
    end
  end
end
