require "kakuro-perms.rb"

describe "Kakuro" do
    before do
        @perm = Kakuro::Perms.new
    end

    it "human->internal transform for 3/2" do
        @perm.human_to_internal(3,2).should eql([1,2])
    end

end
