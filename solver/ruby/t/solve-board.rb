require "kakuro-board.rb"

class Object
    def ok()
        self.should == true
    end
    def not_ok()
        self.should == false
    end
end

describe "Parse 1" do
    before do
        @board = Kakuro::Board.new
        @board.parse(<<'EOF')
[\]    [\]      [29\]  [34\]   [\]      [21\]  [8\]     [\]    [\]
[\]    [10\17]  []     []      [3\3]    []     []       [\]    [\]
[\30]  []       [5]    []      []       [2]    []       [3\]   [11\]
[\16]  []       []     [6]     []       [3]    [12\11]  []     []
[\]    [4\5]    []     []      [13\10]  []     []       []     []
[\34]  []       [7]    []      [4]      []     []       [11\]  [\]
[\4]   []       []     [3\12]  []       []     [1]      []     [\]
[\]    [\]      [\6]   []      []       [\11]  []       []     [\]
[\]    [\]      [\3]   []      []       [\]    [\]      [\]    [\]
EOF
    end

    it "should merge constraints correctly" do
        @board.prepare()
        @board.merge_constraints()
    end

end

