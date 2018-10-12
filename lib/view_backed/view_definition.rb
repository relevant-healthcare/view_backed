module ViewBacked
  class ViewDefinition
    Column = Rails.version.match(/^5/) ? ColumnRails5 : ColumnRails4

    attr_reader :view_name

    def initialize(view_name)
      @view_name = view_name
    end

    def columns
      selections.map(&:column)
    end

    def scope
      selections.inject(from) do |acc, selection|
        acc.select("(#{selection.expression}) AS #{selection.column.name}")
      end
    end

    def string(name, expression = name.to_s)
      column(name, :string, expression)
    end

    def integer(name, expression = name.to_s)
      column(name, :integer, expression)
    end

    def date(name, expression = name.to_s)
      column(name, :date, expression)
    end

    def decimal(name, expression = name.to_s)
      column(name, :decimal, expression)
    end

    def column(name, data_type, expression = name.to_s)
      selections << Selection.new(
        Column.new(name, nil, data_type).to_active_record_column,
        expression
      )
    end

    def from(from = nil)
      @from ||= from
    end

    private

    def selections
      @selections ||= []
    end

    class Selection
      attr_reader :column

      def initialize(column, expression)
        @column = column
        @expression = expression
      end

      def expression
        @expression.try(:to_sql) || @expression
      end
    end
  end
end
