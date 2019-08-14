require 'view_backed/column_rails_4'
require 'view_backed/column_rails_5'
require 'view_backed/view_definition'
require 'view_backed/rails_5'
require 'view_backed/materialized_view'

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
      with_materialized_view do |materialized_view|
        materialized_view.ensure_current!
        materialized_view.refresh!
      end
    end

    def view
      yield view_definition

      default_scope do
        if materialized
          materialize!
          all
        else
          from "(#{view_definition.scope.to_sql}) AS #{table_name}"
        end
      end
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end

    def materialize!
      with_materialized_view do |materialized_view|
        materialized_view.ensure_current!
        sleep 1 until materialized_view.populated?
      end
    end

    private

    def with_materialized_view
      yield MaterializedView.new(
        name: table_name,
        sql: view_definition.scope.to_sql,
        indexed_column_names: view_definition.indexed_column_names
      )
    end
  end
end
