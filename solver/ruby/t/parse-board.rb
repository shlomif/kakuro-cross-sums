require "kakuro-board.rb"

describe "Parse 1" do
    before do
        @board = Kakuro::Board.new
        @board.parse(<<'EOF')
[\] [\] [29\] [\34\] [\] [21\] [8\] [\] [\]
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
        @board.cell_yx(0,0).solid?.should
        @board.cell_yx(0,1).solid?.should
        @board.cell_yx(0,2).solid?.should
        @board.cell_yx(1,2).solid?.should_not
        @board.cell_yx(1,3).solid?.should_not
        @board.cell_yx(1,4).solid?.should
        @board.cell_yx(1,5).solid?.should_not
        @board.cell_yx(1,5).solid?.should_not
        @board.cell_yx(1,6).solid?.should_not
        @board.cell_yx(1,6).solid?.should_not
        @board.cell_yx(1,7).solid?.should
        @board.cell_yx(1,8).solid?.should
        @board.cell_yx(8,0).solid?.should
        @board.cell_yx(8,1).solid?.should
        @board.cell_yx(8,2).solid?.should
        @board.cell_yx(8,3).solid?.should_not
        @board.cell_yx(8,4).solid?.should_not
        @board.cell_yx(8,5).solid?.should
        @board.cell_yx(8,6).solid?.should
        @board.cell_yx(8,7).solid?.should
        @board.cell_yx(8,8).solid?.should
    end

end



