require 'view_backed/view_definition'

module ViewBacked::Model
  extend ActiveSupport::Concern

  def read_only?
    true
  end

  class_methods do
    delegate :columns, to: :view_definition

    def view
      yield view_definition

      default_scope do
        from "(#{view_definition.scope.to_sql}) AS #{table_name}"
      end
    end

    def type_for_attribute(attribute)
      columns_hash[attribute].sql_type_metadata
    end

    def columns_hash
      @columns_hash ||= columns.each_with_object({}) do |column, acc|
        acc[column.name] = column
      end
    end

    def view_definition
      @view_definition ||= ViewBacked::ViewDefinition.new(table_name)
    end
  end
end
