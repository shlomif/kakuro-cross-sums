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
require "kakuro_solver/perms"
require "kakuro_solver/perms_db"
require 'enumerator'

module Enumerable
    def kakuro_collect_dirty
        return inject(false) do |dirty, elem|
            ret = yield(elem)
            dirty || ret
        end
    end

    def kakuro_combine_masks
        return inject(0) { |total,x| (total | x) }
    end
end

module Kakuro
    
    # Some constants
    DOWN = VERT = 0
    RIGHT = HORIZ = 1

    DIRS = [VERT, HORIZ,]

    class ParsingError < RuntimeError
        def initialize()
        end
    end

    class Verdicts
        MAX_DIGIT = 9

        VERDICTS_MAP = (1 .. MAX_DIGIT).map { |x| x-1 }.inject({}) { 
            |h, n| h[1 << n] = n ; h
        }

        def initialize
            return
        end

        def contains(bitmask)
            if VERDICTS_MAP.has_key?(bitmask)
                @val = VERDICTS_MAP[bitmask]
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

    class InitConstraint
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

            calc_all

        end

        private

        def calc_dir_constraint(dir)
            other_dir = 1 - dir

            t_mask = @constraints[other_dir].kakuro_combine_masks
            @possible_cell_values &= t_mask

            @remaining_constraints[dir] = \
                @constraints[dir].select do |constraint| 
                    (((constraint & t_mask) != 0) &&
                     (constraint & @initial_cell_values != 0))
                end

            return
        end

        def calc_constraints_loop
            DIRS.each do |dir|
                calc_dir_constraint(dir)
            end
        end

        def calc_all

            @remaining_constraints = []
            @possible_cell_values = @initial_cell_values

            calc_constraints_loop

            return
        end

        public

        attr_reader :possible_cell_values

        def remaining_dir_constraints(dir)
            return @remaining_constraints[dir]         
        end

        def has_single_verdict
            return Verdicts.new.total_lookup(@possible_cell_values)
        end
    end

    class Cell

        attr_reader :board, :verdict, :verdicts_mask

        def initialize(board, content)
            @board = board
            @user_sums = []
            @control_cells = []
            @constraints = []
            @init_constraints = []
            @dirty = false

            process_text(content)

        end

        private

        def init_solid(vert, horiz)
            @is_solid = true

            if vert.length > 0
                @user_sums[Kakuro::DOWN] = vert.to_i();
            end
            if horiz.length > 0
                @user_sums[Kakuro::RIGHT] = horiz.to_i();
            end

            return
        end

        def init_digit(digit)
            @is_solid = false
            @verdicts_mask = ((1 << 10) - 1)

            if digit.length > 0
                @verdict = digit.to_i()-1
                @verdicts_mask = 1 << @verdict
            end

            return
        end

        def process_text(content)
            if (content =~ /^\s*(\d*)\s*\\\s*(\d*)\s*$/)
                return init_solid($1,$2)
            elsif (content =~ /^\s*(\d*)\s*$/)
                return init_digit($1)
            else
                raise ParsingError.new, \
                    "Cell contains invalid content '#{content}'"
            end
        end

        def known?
            return @verdict
        end

        def board_control_cells
            return @control_cells.map { |pos| board.cell(pos) }
        end

        def calc_verdict
            return @verdict = Verdicts.new.total_lookup(@verdicts_mask)
        end

        def set_possible_merger_verdicts
            return set_possible_verdicts(@merger.possible_cell_values)
        end

        def set_possible_verdicts_with_propagation
            if set_possible_merger_verdicts && calc_verdict
                propagate_conclusive_verdict
            end

            return
        end

        def board_cells_constraints
            return DIRS.map { |dir| board_control_cells[dir].constraint(dir) } 
        end

        def filter_constraint_with_mask(dir, mask)
            return set_new_constraint(
                dir,
                constraint(dir).select { |c| (c & mask) == c }
            )
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
            @init_constraints[dir] = InitConstraint.new(
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

        def set_new_constraint(dir, new_constraint)
            if new_constraint.length < constraint(dir).length
                @dirty = true
            end

            @constraints[dir] = new_constraint

            return flush_dirty
        end

        def filter_possible_constraint(dir, mask_promise)
            return constraint(dir) && 
                filter_constraint_with_mask(dir, mask_promise.call())
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
            @merger = nil
            return ret
        end

        def human_verdict
            return verdict+1
        end

        private
        def set_control_cell_constraint(dir)
            return board_control_cells[dir].set_new_constraint(
                dir,
                @merger.remaining_dir_constraints(dir)
            )
        end

        def init_merger
            @merger = CellConstraintsMerger.new(
                :constraints => board_cells_constraints,
                :cell_values => verdicts_mask
            )
        end

        def set_all_control_cell_constraints
            @dirty = DIRS.kakuro_collect_dirty do |dir|
                set_control_cell_constraint(dir)
            end

            return
        end

        public
        def merge_constraints_step
            init_merger

            set_all_control_cell_constraints
            set_possible_verdicts_with_propagation

            return flush_dirty
        end
    end

    class Board

        def initialize()
            @matrix = Array.new
            @height = nil
            @width = nil
        end

        private

        def row_from_line(line)
            row = Array.new

            while line.sub!(/\A\s*\[([^\]]*)\]\s*/, "")
                row << Cell.new(self, $1)
            end

            verify_line_end(line)

            return row
        end

        def assign_or_verify_width(width)
            if (@width)
                if (width != @width)
                    raise ParsingError.new, \
                        "width of rows (in cells) is not identical"
                end
            else
                @width = width
            end
        end

        def verify_line_end(line)
            # Remove trailing space.
            line.sub!(/\A\s*/, "");
            # Die if there's junk after the line.
            if line.length > 0
                raise ParsingError.new, \
                    "Junk after line"
            end
        end

        def parse_line(line)

            row = row_from_line(line)

            assign_or_verify_width(row.length)

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
            return @matrix[pos.y][pos.x];
        end

        class Coords_Loop
            include Enumerable

            def initialize(max_pos)
                @max_pos = max_pos
            end

            def each
                (0 .. @max_pos.y).each do |y|
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

        class ConstraintHandler
            def initialize(board, init_pos, dir)
                @board = board
                @init_pos = init_pos
                @dir = dir
            end

            def run
                return init_cell.filter_possible_constraint(
                    dir,
                    lambda { board.calc_total_mask(init_pos, dir) }
                )
            end

            private
            attr_reader :dir, :init_pos, :board

            def init_cell
                return board.cell(init_pos)
            end
        end

        def filter_constraints_cell_constraint_step(init_pos, dir)
            return ConstraintHandler.new(self, init_pos, dir).run
        end

        def filter_constraints_cell_step(init_pos)
            return DIRS.kakuro_collect_dirty do |dir|
                filter_constraints_cell_constraint_step(init_pos, dir)
            end
        end

        public

        def calc_total_mask(init_pos, dir)
            return dir_cells_enum(init_pos, dir).map { |x| x.verdicts_mask }.
                kakuro_combine_masks
        end

        def dir_iter_params(dir)
            return ((dir == DOWN) \
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
