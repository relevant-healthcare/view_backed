module ViewBacked
  class ViewDefinition
    Column = Rails.version.match(/^(5|6)/) ? ColumnRails5Or6 : ColumnRails4

    attr_reader :view_name

    delegate :to_sql, to: :scope

    def initialize(view_name)
      @view_name = view_name
    end

    def columns
      selections.map(&:column)
    end

    def indices
      selections.map(&:index).compact
    end

    def scope
      selections.inject(from) do |acc, selection|
        acc.select("(#{selection.expression}) AS #{selection.column.name}")
      end
    end

    def string(name, expression = name.to_s, options = {})
      column(name, :string, expression, options)
    end

    def integer(name, expression = name.to_s, options = {})
      column(name, :integer, expression, options)
    end

    def date(name, expression = name.to_s, options = {})
      column(name, :date, expression, options)
    end

    def decimal(name, expression = name.to_s, options = {})
      column(name, :decimal, expression, options)
    end

    def boolean(name, expression = name.to_s, options = {})
      column(name, :boolean, expression, options)
    end

    def column(name, data_type, expression = name.to_s, options = {})
      selections << Selection.new(
        Column.new(name, nil, data_type).to_active_record_column,
        expression,
        options
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
      attr_reader :column, :options
      delegate :name, to: :column, prefix: true

      def initialize(column, expression, options = {})
        @column = column
        @expression = expression
        @options = options
      end

      def expression
        @expression.try(:to_sql) || @expression
      end

      def index
        return nil unless options[:index]
        index_options = options[:index] == true ? { unique: false } : options[:index]
        Index.new(column_name, index_options)
      end
    end

    class Index
      attr_reader :column_name, :options

      def initialize(column_name, options)
        @column_name = column_name
        @options = options
      end

      def unique?
        options[:unique]
      end
    end
  end
end
