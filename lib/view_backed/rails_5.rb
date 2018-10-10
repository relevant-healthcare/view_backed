module ViewBacked
  module Rails5
    def view
      super

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
end
