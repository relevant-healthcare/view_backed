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
    end

    private

    def view_definition
      @view_definition ||= ViewDefinition.new(table_name)
    end
  end
end
