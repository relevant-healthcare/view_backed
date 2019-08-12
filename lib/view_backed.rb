require 'view_backed/column_rails_4'
require 'view_backed/column_rails_5'
require 'view_backed/view_definition'
require 'view_backed/rails_5'

module ViewBacked
  extend ActiveSupport::Concern

  def read_only?
    true
  end

  class_methods do
    delegate :columns, to: :view_definition
    prepend ViewBacked::Rails5 if Rails.version.match(/^5/)

    def materialized(_materialized = false)
      @materialized ||= _materialized
    end

    # def queries(*queried_tables)

    # end

    def refresh!
      connection.execute "REFRESH MATERIALIZED VIEW #{table_name};"
    end

    def view
      yield view_definition

      if materialized
        connection.execute <<~SQL.squish
          DROP MATERIALIZED VIEW IF EXISTS #{table_name};
          CREATE MATERIALIZED VIEW #{table_name} AS (#{view_definition.scope.to_sql});
        SQL

        create_indices!
      else
        default_scope do
          from "(#{view_definition.scope.to_sql}) AS #{table_name}"
        end
      end
    end

    def create_indices!
      view_definition.indexed_column_names.map do |column_name|
        "CREATE INDEX #{table_name} ON (#{column_name});"
      end.join("\n")
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end
  end
end
