require "kakuro-board.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
    end
end

class Position < Kakuro::Position
end

describe "Variable Width Board" do
    it "should not be accepted with variable width" do
        board = Kakuro::Board.new
        got_exception = false
        begin
            board.parse(<<'EOF')
[\3] [] []
[\] []
[\] [] []
EOF

        rescue Kakuro::ParsingError
            got_exception = true
        end
        got_exception.ok()
    end
end

describe "Parse 1" do
    before do
        @board = Kakuro::Board.new
        @board.parse(<<'EOF')
[\] [\] [29\] [34\] [\] [21\] [8\] [\] [\]
[\] [10\17] [] [] [3\3] [] [] [\] [\]
[\30] [] [5] [] [] [2] [] [3\] [11\]
[\16] [] [] [6] [] [3] [12\11] [] []
[\] [4\5] [] [] [13\10] [] [] [] []
[\34] [] [7] [] [4] [] [] [11\] [\]
[\4] [] [] [3\12] [] [] [1] [] [\] 
[\] [\] [\6] [] [] [\11] [] [] [\]
[\] [\] [\3] [] [] [\] [\] [\] [\]
EOF
    end

    it "cells are solid or not" do
        @board.cell_yx(Position.new(:x => 0, :y => 0)).solid?.ok
        @board.cell_yx(Position.new(:x => 1, :y => 0)).solid?.ok
        @board.cell_yx(Position.new(:x => 2, :y => 0)).solid?.ok
        @board.cell_yx(Position.new(:x => 2, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 3, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 4, :y => 1)).solid?.ok
        @board.cell_yx(Position.new(:x => 5, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 5, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 6, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 6, :y => 1)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 7, :y => 1)).solid?.ok
        @board.cell_yx(Position.new(:x => 8, :y => 1)).solid?.ok
        @board.cell_yx(Position.new(:x => 0, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 1, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 2, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 3, :y => 8)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 4, :y => 8)).solid?.not_ok
        @board.cell_yx(Position.new(:x => 5, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 6, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 7, :y => 8)).solid?.ok
        @board.cell_yx(Position.new(:x => 8, :y => 8)).solid?.ok
    end

    it "should contain the correct sums" do
        @board.cell_yx(Position.new(:x => 2, :y => 0)).user_sum(Kakuro::Down).should == 29
        @board.cell_yx(Position.new(:x => 3, :y => 0)).user_sum(Kakuro::Down).should == 34
        @board.cell_yx(Position.new(:x => 7, :y => 2)).user_sum(Kakuro::Down).should == 3
        @board.cell_yx(Position.new(:x => 1, :y => 1)).user_sum(Kakuro::Down).should == 10
        @board.cell_yx(Position.new(:x => 1, :y => 1)).user_sum(Kakuro::Right).should == 17
        @board.cell_yx(Position.new(:x => 0, :y => 2)).user_sum(Kakuro::Right).should == 30
        @board.cell_yx(Position.new(:x => 2, :y => 0)).user_sum(Kakuro::Right).should be_nil
        @board.cell_yx(Position.new(:x => 0, :y => 0)).user_sum(Kakuro::Right).should be_nil
        @board.cell_yx(Position.new(:x => 0, :y => 0)).user_sum(Kakuro::Down).should be_nil
        @board.cell_yx(Position.new(:x => 0, :y => 2)).user_sum(Kakuro::Down).should be_nil
        @board.cell_yx(Position.new(:x => 2, :y => 2)).verdict.should == 5
    end
end

describe "Cells with errors (1)" do
    it "should throw an exception" do
        board = Kakuro::Board.new
        lambda {
            board.parse(<<'EOF')
[3forward]
EOF
        }.should raise_error(Kakuro::ParsingError)
    end
end

describe "Junk after line" do
    it "should throw an exception" do
        board = Kakuro::Board.new
        lambda {
            board.parse(<<'EOF')
[\] [\] [29\] [34\] [\] [21\] [8\] [\] [\]
[\] [10\17] [] [] [3\3] [] [] [\] [\] This is wrong.
[\30] [] [5] [] [] [2] [] [3\] [11\]
EOF
        }.should raise_error(Kakuro::ParsingError)
    end
end

describe "Post-Parse Prepared Board" do
    before do
        @board = Kakuro::Board.new
        @board.parse(<<'EOF')
[\] [\] [29\] [34\] [\] [21\] [8\] [\] [\]
[\] [10\17] [] [] [3\3] [] [] [\] [\]
[\30] [] [5] [] [] [2] [] [3\] [11\]
[\16] [] [] [6] [] [3] [12\11] [] []
[\] [4\5] [] [] [13\10] [] [] [] []
[\34] [] [7] [] [4] [] [] [11\] [\]
[\4] [] [] [3\12] [] [] [1] [] [\] 
[\] [\] [\6] [] [] [\11] [] [] [\]
[\] [\] [\3] [] [] [\] [\] [\] [\]
EOF
        @board.prepare()
    end

    it "should give the right constraints" do

        @board.cell_yx(Position.new(:x => 1, :y => 1)).constraint(Kakuro::Down).num_cells.should == 2
        @board.cell_yx(Position.new(:x => 1, :y => 1)).constraint(Kakuro::Down).sum.should == 8

        @board.cell_yx(Position.new(:x => 1, :y => 1)).constraint(Kakuro::Right).num_cells.should == 2
        @board.cell_yx(Position.new(:x => 1, :y => 1)).constraint(Kakuro::Right).sum.should == 15

        @board.cell_yx(Position.new(:x => 2, :y => 1)).control_cell(Kakuro::Horiz).x.should == 1
        @board.cell_yx(Position.new(:x => 2, :y => 1)).control_cell(Kakuro::Horiz).y.should == 1
        @board.cell_yx(Position.new(:x => 2, :y => 1)).control_cell(Kakuro::Vert).x.should == 2
        @board.cell_yx(Position.new(:x => 2, :y => 1)).control_cell(Kakuro::Vert).y.should == 0
        @board.cell_yx(Position.new(:x => 1, :y => 3)).control_cell(Kakuro::Vert).x.should == 1
        @board.cell_yx(Position.new(:x => 1, :y => 3)).control_cell(Kakuro::Vert).y.should == 1

        # Testing for out-of-board constraints.
        @board.cell_yx(Position.new(:x => 4, :y => 4)).constraint(Kakuro::Right).num_cells.should == 4
        @board.cell_yx(Position.new(:x => 4, :y => 4)).constraint(Kakuro::Right).sum.should == 6

        @board.cell_yx(Position.new(:x => 3, :y => 6)).constraint(Kakuro::Down).num_cells.should == 2
        @board.cell_yx(Position.new(:x => 3, :y => 6)).constraint(Kakuro::Down).sum.should == 1
    end
end
