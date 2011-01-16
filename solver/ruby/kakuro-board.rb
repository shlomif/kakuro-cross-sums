#--
# Copyright (c) 2011 Shlomi Fish
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require "kakuro-perms.rb"
require "kakuro-perms-db.rb"
require 'enumerator'

module Enumerable
    def kakuro_collect_dirty
        return inject(false) do |dirty, elem|
            ret = yield(elem)
            dirty || ret
        end
    end
end

module Kakuro
    
    # Some constants
    Down = Vert = 0
    Right = Horiz = 1

    DIRS = [Vert, Horiz,]

    class ParsingError < RuntimeError
        def initialize()
        end
    end

    class Verdicts
        MAX_DIGIT = 9

        Verdicts_Map = (1 .. MAX_DIGIT).map { |x| x-1 }.inject({}) { 
            |h, n| h[1 << n] = n ; h
        }

        def initialize
            return
        end

        def contains(bitmask)
            if Verdicts_Map.has_key?(bitmask)
                @val = Verdicts_Map[bitmask]
                return true
            else
                @val = nil
                return false
            end
        end

        def lookup
            return @val
        end

        def total_lookup(bitmask)
            return contains(bitmask) ? lookup() : false
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

    class CellConstraintsMerger

        def initialize(args)

            @constraints = args[:constraints]
            @initial_cell_values = args[:cell_values]

            calc_dir_constraints()

        end

        private

        def combine_masks(masks_a)
            return masks_a.inject(0) { |total, x| (total | x) }
        end

        public

        def calc_dir_constraints

            @total_masks = []
            @remaining_constraints = []

            DIRS.each do |dir|
                other_dir = 1 - dir

                t_mask = @total_masks[other_dir] = 
                    combine_masks(@constraints[other_dir])

                @remaining_constraints[dir] = \
                    @constraints[dir].select do |constraint| 
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

        def has_single_verdict
            return Verdicts.new.total_lookup(@possible_cell_values)
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

        private
        def known?
            return @verdict
        end

        def board_control_cells
            return @control_cells.map { |pos| board.cell(pos) }
        end

        def set_possible_verdicts_with_propagation(verdicts)
            if set_possible_verdicts(verdicts)
                v = Verdicts.new
                if (v.contains(@verdicts_mask))
                    @verdict = v.lookup
                    propagate_conclusive_verdict
                end
            end

            return
        end

        def board_cells_constraints
            return DIRS.map { |dir| board_control_cells[dir].constraint(dir) } 
        end

        public

        def solid?
            return @is_solid
        end

        def fillable?
            return !solid?
        end

        def to_be_filled?
            return (fillable? && (! known?))
        end

        def filled?
            return (fillable? && known?)
        end

        def user_sum(direction)
            return @user_sums[direction]
        end

        def set_control(direction, pos)
            @control_cells[direction] = pos
            return true
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

            return flush_dirty
        end

        def get_possible_verdicts
            return (0 .. 8).select { |x| (@verdicts_mask & (1 << x)) != 0 }
        end

        def set_possible_verdicts(verdicts)
            changed = (verdicts != @verdicts_mask)
            if changed
                @dirty = true
            end

            @verdicts_mask = verdicts

            return changed
        end

        def filter_constraint(dir, verdict)
            # puts "Filtering #{dir} with #{verdict}"
            @constraints[dir] = @constraints[dir].map { |x| 
                # puts "Old x : #{x} ; New x : #{x & (~(1 << verdict))}"
                x & (~(1 << verdict)) 

            }
            @dirty = true
        end

        def propagate_conclusive_verdict
            DIRS.each do |dir|
                board_control_cells[dir].filter_constraint(dir, verdict);
            end
        end

        def flush_dirty
            ret = @dirty
            @dirty = false
            return ret
        end

        def human_verdict
            return verdict+1
        end

        def merge_constraints_step

            merger = CellConstraintsMerger.new(
                :constraints => board_cells_constraints,
                :cell_values => verdicts_mask
            )

            DIRS.each do |dir|
                ret = board_control_cells[dir].set_new_constraint(
                    dir,
                    merger.remaining_dir_constraints(dir)
                )
                @dirty ||= ret
            end

            set_possible_verdicts_with_propagation(
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

        private

        def next_cell_id()
            ret = @next_cell_id
            @next_cell_id += 1
            return ret
        end

        def parse_line(line)
            width = 0
            row = []
            while line.sub!(/\A\s*\[([^\]]*)\]\s*/, "")
                content = $1

                cell = Cell.new(self, next_cell_id(), content)

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

        public

        def parse(board_string)
            board_string.split(/\n+/).each do |line|
                parse_line(line)
            end
            @height = @matrix.length
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

        [:solid, :to_be_filled, :filled].each do |meth| 
            define_method "#{meth}_coords" do
                all_coords.select { |pos| cell(pos).send("#{meth}?") }
            end
        end

        private

        class Dirs_Iter
            include Enumerable

            def initialize(init_pos, dir, dim, bump_dir)
                @pos = init_pos
                @dir = dir
                @dim = dim
                @bump_dir = bump_dir
            end

            def each
                while (@pos.send(@dir) < @dim - 1)
                    @pos = @pos.send(@bump_dir)
                    yield @pos
                end
            end
        end

        class Dirs_Cell_Iter
            include Enumerable

            def initialize(board, init_pos, dir)
                @board = board
                @pos = init_pos
                @dirs_iter = Dirs_Iter.new(@pos, *@board.dir_iter_params(dir))
            end

            def each
                @dirs_iter.each do |pos|
                    mycell = @board.cell(pos)
                    if mycell.fillable?
                        yield mycell
                    else
                        break
                    end
                end
            end
        end
        def dir_cells_enum(init_pos, dir)
            return Dirs_Cell_Iter.new(self, init_pos, dir)
        end

        def calc_cell_constraints(init_pos)
            solid_cell = cell(init_pos)

            DIRS.each do |dir|
                user_sum = solid_cell.user_sum(dir)

                if user_sum
                    count = dir_cells_enum(init_pos, dir).count { 
                        |c| c.set_control(dir, init_pos)
                    }

                    solid_cell.set_num_cells(dir, count)
                end
            end
        end

        def merge_constraint_cell_step(pos)
            return cell(pos).merge_constraints_step
        end

        def merge_constraints_scan
            return to_be_filled_coords.kakuro_collect_dirty do |pos| 
                merge_constraint_cell_step(pos)
            end
        end

        def filter_constraints_cell_constraint_step(init_pos, dir)
            init_cell = cell(init_pos)
            constraint = init_cell.constraint(dir)

            if (constraint)
                total_mask = dir_cells_enum(init_pos, dir).inject(0) { 
                    |t, c| t | c.verdicts_mask
                }

                return init_cell.set_new_constraint(
                    dir,
                    constraint.select { |c| (c & total_mask) == c }
                )
            else
                return false
            end
        end

        def filter_constraints_cell_step(init_pos)
            return DIRS.kakuro_collect_dirty do |dir|
                filter_constraints_cell_constraint_step(init_pos, dir)
            end
        end

        public

        def dir_iter_params(dir)
            return ((dir == Down) \
                ? ['y',@height,'bump_y'] \
                : ['x',@width,'bump_x'])
        end

        def prepare()
            solid_coords.each do |pos|
                calc_cell_constraints(pos)
            end
            filled_coords.each do |pos|
                cell(pos).propagate_conclusive_verdict
            end
        end

        def merge_constraints
            true while merge_constraints_scan()

            return
        end

        def filter_constraints_without_cells
            return solid_coords.kakuro_collect_dirty do |pos|
                filter_constraints_cell_step(pos)
            end
        end
    end


end
