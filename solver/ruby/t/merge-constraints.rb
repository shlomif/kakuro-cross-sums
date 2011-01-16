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
require "kakuro-board.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
    end
end

describe "Merge Two Constraints" do
    it "[1,2] and [1,3] should be merged" do
        vert = Kakuro::Constraint.new(2,2).as_list
        horiz = Kakuro::Constraint.new(1,2).as_list

        merger = Kakuro::CellConstraintsMerger.new(
            :constraints => [vert,horiz,],
            :cell_values => (0..8).inject(0) { |total,x| (total | (1 << x))}
        )
        
        merger.remaining_dir_constraints(Kakuro::Vert).should == \
            [(1 << 0)|(1 << 2)]
        merger.remaining_dir_constraints(Kakuro::Horiz).should == \
            [(1 << 0)|(1 << 1)]

        merger.possible_cell_values.should == (1 << 0)

        merger.has_single_verdict.should == 0
    end
end

describe "[[1,2]] and [[1,8],[2,7],[3,6],[4,5]]" do
    it "should be merged" do
        vert = Kakuro::Constraint.new(
            *Kakuro::Perms.new.human_to_internal(3,2)
        ).as_list
        horiz = Kakuro::Constraint.new(
            *Kakuro::Perms.new.human_to_internal(9,2)
        ).as_list

        merger = Kakuro::CellConstraintsMerger.new(
            :constraints => [vert,horiz,],
            :cell_values => ((0..8).inject(0) { |total,x| (total | (1 << x))})
        )
        
        merger.remaining_dir_constraints(Kakuro::Vert).should == \
            [(1 << 0)|(1 << 1)]
        merger.remaining_dir_constraints(Kakuro::Horiz).should == \
            [ ((1 << 0)|(1 << 7)), ((1 << 1)|(1 << 6)), ]

        merger.possible_cell_values.should == ((1 << 0)|(1 << 1))

        merger.has_single_verdict.should == false
    end
end

describe "[[1,2]] and [[1,8],[2,7],[3,6],[4,5]] with 1 alone" do
    it "should be merged" do
        vert = Kakuro::Constraint.new(
            *Kakuro::Perms.new.human_to_internal(3,2)
        ).as_list
        horiz = Kakuro::Constraint.new(
            *Kakuro::Perms.new.human_to_internal(9,2)
        ).as_list

        merger = Kakuro::CellConstraintsMerger.new(
            :constraints => [vert,horiz,],
            :cell_values => ((0..0).inject(0) { |total,x| (total | (1 << x))})
        )
        
        merger.remaining_dir_constraints(Kakuro::Vert).should == \
            [(1 << 0)|(1 << 1)]
        merger.remaining_dir_constraints(Kakuro::Horiz).should == \
            [ ((1 << 0)|(1 << 7)), ]

        merger.possible_cell_values.should == (1 << 0)

        merger.has_single_verdict.should == 0
    end
end

