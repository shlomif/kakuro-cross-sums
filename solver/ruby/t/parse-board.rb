require "kakuro-board.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
    end
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
        @board.cell_yx(0,0).solid?.ok
        @board.cell_yx(0,1).solid?.ok
        @board.cell_yx(0,2).solid?.ok
        @board.cell_yx(1,2).solid?.not_ok
        @board.cell_yx(1,3).solid?.not_ok
        @board.cell_yx(1,4).solid?.ok
        @board.cell_yx(1,5).solid?.not_ok
        @board.cell_yx(1,5).solid?.not_ok
        @board.cell_yx(1,6).solid?.not_ok
        @board.cell_yx(1,6).solid?.not_ok
        @board.cell_yx(1,7).solid?.ok
        @board.cell_yx(1,8).solid?.ok
        @board.cell_yx(8,0).solid?.ok
        @board.cell_yx(8,1).solid?.ok
        @board.cell_yx(8,2).solid?.ok
        @board.cell_yx(8,3).solid?.not_ok
        @board.cell_yx(8,4).solid?.not_ok
        @board.cell_yx(8,5).solid?.ok
        @board.cell_yx(8,6).solid?.ok
        @board.cell_yx(8,7).solid?.ok
        @board.cell_yx(8,8).solid?.ok
    end

    it "should contain the correct sums" do
        @board.cell_yx(0,2).user_sum(Kakuro::Down).should == 29
        @board.cell_yx(0,3).user_sum(Kakuro::Down).should == 34
        @board.cell_yx(2,7).user_sum(Kakuro::Down).should == 3
        @board.cell_yx(1,1).user_sum(Kakuro::Down).should == 10
        @board.cell_yx(1,1).user_sum(Kakuro::Right).should == 17
        @board.cell_yx(2,0).user_sum(Kakuro::Right).should == 30
        @board.cell_yx(0,2).user_sum(Kakuro::Right).should be_nil
        @board.cell_yx(0,0).user_sum(Kakuro::Right).should be_nil
        @board.cell_yx(0,0).user_sum(Kakuro::Down).should be_nil
        @board.cell_yx(2,0).user_sum(Kakuro::Down).should be_nil
        @board.cell_yx(2,2).verdict.should == 5
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
