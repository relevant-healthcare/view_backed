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
    prepend ViewBacked::Rails5 if Rails.version.match?(/^5/)

    def view
      yield view_definition

      default_scope do
        from "(#{view_definition.scope.to_sql}) AS #{table_name}"
      end
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end
  end
end
