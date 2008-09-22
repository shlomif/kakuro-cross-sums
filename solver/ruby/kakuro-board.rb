module Kakuro

    class ParsingError < RuntimeError
        def initialize()
        end
    end

    class Cell

        attr_reader :id

        def initialize(id, content)
            @id = id
            @is_solid = (content =~ /\\/) ? true : false;
        end

        def solid?
            return @is_solid
        end

    end

    class Board

        def initialize()
            @next_cell_id = 0
            @cells = Array.new

            @matrix = Array.new
            @height = nil
            @width = nil
        end

        def parse(board_string)
            board_string.split(/\n+/).each do |line|
                _parse_line(line)
            end
        end

        def _next_cell_id()
            ret = @next_cell_id
            @next_cell_id += 1
            return ret
        end

        def _parse_line(line)
            # TODO : Make sure the widths of all the lines are the same.
            width = 0
            row = []
            while line.sub!(/\A\s*\[([^\]]*)\]\s*/, "")
                content = $1

                cell = Cell.new(_next_cell_id(), content)

                @cells << cell

                width += 1

                row << cell.id
            end

            if (@width)
                if (width != @width)
                    raise ParsingError.new, \
                        "width of rows (in cells) is not identical"
                end
            else
                @width = width
            end
            @matrix.push(row)
        end

        def cell_yx(row,col)
            # Uncomment for debugging:
            # puts "Row = #{row} ; Col = #{col}"
            return @cells[@matrix[row][col]];
        end

    end

end
