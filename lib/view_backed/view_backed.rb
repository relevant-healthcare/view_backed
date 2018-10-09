module ViewBacked
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

      if Rails.version.match?(/^5/)
        @columns_hash = columns.group_by(&:name).transform_values(&:first)
        columns.each do |column|
          define_attribute(
            column.name,
            ActiveModel::Type.registry.lookup(column.type),
            default: column.default
          )
        end
      end
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end
  end
end
