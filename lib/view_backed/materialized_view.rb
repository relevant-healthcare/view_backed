module ViewBacked
  class MaterializedView
    include ActiveModel::Model
    attr_accessor :name, :sql, :indices, :with_data

    def initialize(name:, sql:, indices: [], with_data: true)
      super
    end

    def ensure_current!
      return if exists? && current?

      drop_if_exists!
      create!
    end

    def refresh!
      MaterializedViewRefresh.new(
        connection: connection,
        view_name: name
      ).save!
    end

    def wait_until_populated
      with_wait_until_populated_timeout do
        sleep 1 until populated?
      end
    end

    def with_wait_until_populated_timeout
      return yield if ViewBacked.options[:max_wait_until_populated].blank?

      begin
        Timeout.timeout(ViewBacked.options[:max_wait_until_populated]) { yield }
      rescue Timeout::Error
        raise ViewBacked::MaxWaitUntilPopulatedTimeExceededError
      end
    end

    def populated?
      (db_record || {})['ispopulated'].in? [true, 't']
    end

    def drop_if_exists!
      execute "DROP MATERIALIZED VIEW IF EXISTS #{name};"
    end

    protected

    def create!
      execute "CREATE MATERIALIZED VIEW #{name} AS (#{sql}) WITH NO DATA;"

      refresh! if with_data
      index!
    end

    def definition_in_db
      (db_record || {})['definition']
    end

    private

    delegate :execute, to: :connection

    def index!
      connection.transaction do
        indices.each { |index| create_index!(index) }
      end
    end

    def create_index!(index)
      execute "CREATE#{(' UNIQUE' if index.unique?)} INDEX ON #{name} (#{index.column_name});"
    end

    def exists?
      db_record.present?
    end

    def current?
      with_temp_view do |temp_view|
        temp_view.create!
        # Postgres formats the sql in the definition column of a materialized
        # view in a particular way. In order to compare the current-in-code
        # definition sql with the current-in-database definition sql, we
        # create a dummy temp view. This way, the sql we compare have the same
        # formatting.
        return temp_view.definition_in_db == definition_in_db
      end
    end

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
      execute("SELECT * FROM pg_matviews WHERE matviewname = '#{name}';").first
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
