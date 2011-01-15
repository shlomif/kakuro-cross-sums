require "kakuro-perms.rb"
require "kakuro-perms-db.rb"

module Kakuro
    
    # Some constants
    Down = Vert = 0
    Right = Horiz = 1

    DIRS = [Vert, Horiz,]

    class ParsingError < RuntimeError
        def initialize()
        end
    end

    class Constraint
        attr_reader :num_cells, :sum

        def initialize(sum, num_cells)
            @sum = sum
            @num_cells = num_cells
        end

        def as_list
            return Kakuro::GENERATED_PERMS[@num_cells][@sum]
        end
    end

    class Position
        attr_reader :x, :y
        def initialize(options={})
            @x = options[:x] or raise "x not given"
            @y = options[:y] or raise "y not given"
        end

        def bump_x
            return Position.new(:x => x+1, :y => y)
        end

        def bump_y
            return Position.new(:x => x, :y => y+1)
        end
    end

    class Cell

        attr_reader :board, :id, :verdict, :verdicts_mask

        def initialize(board, id, content)
            @board = board
            @id = id
            @user_sums = []
            @control_cells = []
            @constraints = []
            @init_constraints = []
            @dirty = false
            if (content =~ /^\s*(\d*)\s*\\\s*(\d*)\s*$/)
                @is_solid = true
                if $1.length > 0
                    @user_sums[Kakuro::Down] = $1.to_i();
                end
                if $2.length > 0
                    @user_sums[Kakuro::Right] = $2.to_i();
                end
            elsif (content =~ /^\s*(\d*)\s*$/)
                digit = $1
                @is_solid = false
                @verdicts_mask = ((1 << 10) - 1)
                if digit.length > 0
                    @verdict = digit.to_i()-1
                    @verdicts_mask = 1 << @verdict
                end
            else
                raise ParsingError.new, \
                    "Cell contains invalid content '#{content}'"
            end
        end

        def solid?
            return @is_solid
        end

        def user_sum(direction)
            return @user_sums[direction]
        end

        def set_control(direction, pos)
            @control_cells[direction] = pos
        end

        def control_cell(dir)
            return @control_cells[dir]
        end

        def set_num_cells(dir, num_cells)
            @init_constraints[dir] = Constraint.new(
                *(Kakuro::Perms.new.human_to_internal(
                    user_sum(dir), num_cells
                ))
            )
            @constraints[dir] = @init_constraints[dir].as_list
        end

        def constraint(dir)
            return @constraints[dir]
        end

        def init_constraint(dir)
            return @init_constraints[dir]
        end

        def set_new_constraint(dir, constraint)
            if constraint.length < @constraints[dir].length
                @dirty = true
            end

            @constraints[dir] = constraint

            return
        end

        def get_possible_verdicts
            return (0 .. 8).select { |x| (@verdicts_mask & (1 << x)) != 0 }
        end

        def set_possible_verdicts(verdicts)
            if (verdicts != @verdicts_mask)
                @dirty = true
            end

            @verdicts_mask = verdicts

            return
        end

        def flush_dirty
            ret = @dirty
            @dirty = false
            return ret
        end

        def human_verdict
            return verdict+1
        end

        def _board_control_cells
            return @control_cells.map { |pos| board.cell(pos) }
        end

        def _get_board_cells_constraints
            return DIRS.map { |dir| _board_control_cells[dir].constraint(dir) } 
        end

        def _merge_constraints_step

            merger = CellConstraintsMerger.new(
                :constraints => _get_board_cells_constraints,
                :cell_values => verdicts_mask
            )

            DIRS.each do |dir|
                _board_control_cells[dir].set_new_constraint(
                    dir, 
                    merger.remaining_dir_constraints(dir)
                )
            end

            set_possible_verdicts(
                merger.possible_cell_values
            )

            return flush_dirty
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
            @height = @matrix.length
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

                cell = Cell.new(self, _next_cell_id(), content)

                @cells << cell

                width += 1

                row << cell.id
            end

            # Remove trailing space.
            line.sub!(/\A\s*/, "");
            # Die if there's junk after the line.
            if line.length > 0
                raise ParsingError.new, \
                    "Junk after line"
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

        def cell(pos)
            # Uncomment for debugging:
            # puts "Row = #{row} ; Col = #{col}"
            return @cells[@matrix[pos.y][pos.x]];
        end

        class Coords_Loop
            include Enumerable

            def initialize(max_pos)
                @max_pos = max_pos
            end

            def each
                ( 0 .. @max_pos.y).each do |y|
                    (0 .. @max_pos.x).each do |x|
                        yield Position.new(:x => x, :y => y)
                    end
                end
            end
        end

        def all_coords
            return Coords_Loop.new(Position.new(:x => @width-1, :y=>@height-1))
        end

        def solid_coords
            return all_coords.select { |pos| cell(pos).solid? }
        end

        def coords_to_fill
            return all_coords.select { |pos| not cell(pos).solid? }
        end

        def prepare()
            solid_coords.each do |pos|
                _calc_cell_constraints(pos)
            end
        end

        def get_dir_iter(pos,dir)
            if (dir == Down)
                return lambda { 
                    if (pos.y == @height-1)
                        return false
                    else
                        pos = pos.bump_y
                        return pos
                    end
                }
            else
                return lambda {
                    if (pos.x == @width-1)
                        return false
                    else
                        pos = pos.bump_x
                        return pos
                    end
                }
            end
        end

        def _calc_cell_constraints(init_pos)
            solid_cell = cell(init_pos)

            for dir in [Down, Right]
                user_sum = solid_cell.user_sum(dir)

                if user_sum
                    count = 0
                    iter = get_dir_iter(init_pos, dir)
                    pos = iter.call()
                    while (pos && (! cell(pos).solid?))
                        count += 1
                        cell(pos).set_control(dir, init_pos)
                        pos = iter.call()
                    end
                    iter = nil

                    solid_cell.set_num_cells(dir, count)
                end
            end
        end

        def _merge_constraint_cell_step(pos)
            return cell(pos)._merge_constraints_step
        end

        def _merge_constraints_scan
            return coords_to_fill.inject(false) do |dirty, pos|
                ret = _merge_constraint_cell_step(pos)
                dirty || ret
            end
        end

        def merge_constraints

            while _merge_constraints_scan()
                true
            end

            return

        end
    end

    class CellConstraintsMerger
        def initialize(args)
            @constraints = args[:constraints]
            @initial_cell_values = args[:cell_values]
            calc_dir_constraints()
        end

        def combine_masks(masks_a)
            return masks_a.inject(0) { |total, x| (total | x) }
        end

        def calc_dir_constraints
            @total_masks = []
            @remaining_constraints = []
            DIRS.each do |dir|
                other_dir = 1 - dir
                t_mask = @total_masks[other_dir] = 
                    combine_masks(@constraints[other_dir])
                @remaining_constraints[dir] = \
                    @constraints[dir].select do 
                        |constraint| 
                        (((constraint & t_mask) != 0) &&
                         (constraint & @initial_cell_values != 0))
                    end
            end

            @possible_cell_values = (
                (@initial_cell_values & @total_masks[Vert]) & 
                    @total_masks[Horiz]
            )
        end

        def remaining_dir_constraints(dir)
            return @remaining_constraints[dir]         
        end

        def possible_cell_values
            return @possible_cell_values
        end

        Verdicts_Map = (1 .. 9).map { |x| x-1 }.inject({}) { 
            |h, n| h[1 << n] = n ; h
        }

        def has_single_verdict
            if Verdicts_Map.has_key?(@possible_cell_values)
                return Verdicts_Map[@possible_cell_values]
            else
                return false
            end
        end

    end

end
