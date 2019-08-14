module ViewBacked
  class MaterializedView
    include ActiveModel::Model
    attr_accessor :name, :sql, :indexed_column_names, :with_data

    def initialize(name:, sql:, indexed_column_names: [], with_data: true)
      super
    end

    def drop_if_exists!
      execute "DROP MATERIALIZED VIEW IF EXISTS #{name};"
    end

    def ensure_current!
      return if exists? && current?
      connection.transaction do
        drop_if_exists!
        create!
      end
    end

    def create!
      execute "CREATE MATERIALIZED VIEW #{name} AS (#{sql}) WITH NO DATA;"
      refresh! if with_data
      index!
    end

    def refresh!
      execute "REFRESH MATERIALIZED VIEW #{name};"
    end

    def index!
      execute(
        indexed_column_names.map do |column_name|
          "CREATE INDEX ON #{name} (#{column_name});"
        end.join("\n")
      )
    end

    def exists?
      db_record.present?
    end

    def populated?
      (db_record || {})['ispopulated']
    end

    def current?
      with_temp_view do |temp_view|
        temp_view.create!
        return temp_view.definition_in_db == definition_in_db
      end
    end

    protected

    def definition_in_db
      (db_record || {})['definition']
    end

    private

    def with_temp_view
      temp_view = MaterializedView.new(
        name: "temp_view_backed_#{SecureRandom.hex(6)}_#{name}",
        sql: sql,
        with_data: false
      )
      yield temp_view
    ensure
      temp_view.drop_if_exists!
    end

    def db_record
      @db_record ||= execute("SELECT * FROM pg_matviews WHERE matviewname = '#{name}';").first
    end

    def execute(query)
      connection.execute(query)
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
