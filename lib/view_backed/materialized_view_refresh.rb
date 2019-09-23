module ViewBacked
  class MaterializedViewRefresh
    include ActiveModel::Model
    attr_accessor :view_name, :connection

    def initialize(view_name:, connection:)
      super
    end

    def save!
      connection.execute "REFRESH MATERIALIZED VIEW #{view_name};"
    end
  end
end
