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
        vert = Kakuro::Constraint.new(2,2)
        horiz = Kakuro::Constraint.new(1,2)

        merger = Kakuro::CellConstraintsMerger.new(
            {
                'constraints' => [vert,horiz,],
            }
        )
        
        merger.remaining_dir_constraints(Kakuro::Vert).should == \
            [(1 << 0)|(1 << 2)]
        merger.remaining_dir_constraints(Kakuro::Horiz).should == \
            [(1 << 0)|(1 << 1)]

        merger.possible_cell_values.should == (1 << 0)

        merger.has_single_verdict.should == 0
    end
end

