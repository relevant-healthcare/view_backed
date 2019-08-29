module ViewBacked
  class MaterializedViewRefresh
    include ActiveModel::Model
    attr_accessor :view_name, :connection, :concurrently

    def initialize(view_name:, connection:, concurrently: false)
      super
    end

    def save!
      connection.execute "REFRESH MATERIALIZED VIEW#{(' CONCURRENTLY' if concurrently)} #{view_name};"
    end
  end
end
