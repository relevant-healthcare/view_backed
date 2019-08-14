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

    def queries(*queried_tables)
      @queries ||= queried_tables
    end

    def refresh!
      ensure_materialized!
      connection.execute "REFRESH MATERIALIZED VIEW #{table_name};"
    end

    def view
      yield view_definition

      default_scope do
        if materialized
          ensure_materialized!
          all
        else
          from "(#{view_definition.scope.to_sql}) AS #{table_name}"
        end
      end
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end

    def definition_has_changed?
      staged_view_name = "staged_#{table_name}"

      staged_view = connection.execute(<<~SQL.squish).first
        DROP MATERIALIZED VIEW IF EXISTS #{staged_view_name};
        CREATE MATERIALIZED VIEW #{staged_view_name} AS (#{view_definition.scope.to_sql}) WITH NO DATA;
        SELECT * FROM pg_matviews WHERE matviewname = '#{staged_view_name}';
      SQL

      staged_view['definition'] != existing_view_definition
    ensure
      connection.execute <<~SQL.squish
        DROP MATERIALIZED VIEW IF EXISTS #{staged_view_name};
      SQL
    end

    def view_exists?
      existing_view.present?
    end

    def existing_view
      connection.execute(<<~SQL.squish).first
        SELECT * FROM pg_matviews WHERE matviewname = '#{table_name}';
      SQL
    end

    def existing_view_definition
      (existing_view || {})['definition']
    end

    def ensure_materialized!
      return if view_exists? || !definition_has_changed?
      materialize!
    end

    def materialize!
      connection.execute <<~SQL.squish
        DROP MATERIALIZED VIEW IF EXISTS #{table_name};
        CREATE MATERIALIZED VIEW #{table_name} AS (#{view_definition.scope.to_sql});
      SQL

      create_indices!
    end

    def create_indices!
      view_definition.indexed_column_names.map do |column_name|
        "CREATE INDEX #{table_name} ON (#{column_name});"
      end.join("\n")
    end
  end
end
