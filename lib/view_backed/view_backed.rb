module ViewBacked
  extend ActiveSupport::Concern

  def read_only?
    true
  end

  class_methods do
    delegate :columns, to: :view_definition

    def view
      yield view_definition

      if Module.const_defined? 'ActiveModel::Type'
        @columns_hash = columns.group_by(&:name).transform_values(&:first)
        @columns_hash.each do |name, column|
          define_attribute(
            name,
            ActiveModel::Type.registry.lookup(column.type),
            default: column.default,
            user_provided_default: false
          )
        end
      end

      default_scope do
        from "(#{view_definition.scope.to_sql}) AS #{table_name}"
      end
    end

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end
  end
end
