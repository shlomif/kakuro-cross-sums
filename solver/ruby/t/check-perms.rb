require "kakuro-perms.rb"

def human_get_perms(mutator, sum, num)
    perms = mutator.get_perms(*mutator.human_to_internal(sum, num))
    return perms.map {|x| mutator.internal_to_human(x) }
end

describe "Kakuro" do
    before do
        @perm = Kakuro::Perms.new
    end

    it "human->internal transform for 3/2" do
        @perm.human_to_internal(3,2).should eql([1,2])
    end

    it "human->internal transform for 5/2" do
        @perm.human_to_internal(5,2).should eql([3,2])
    end

    it "human->internal transform for 10/4" do
        # 10 = 1 + 2 + 3 + 4
        # 10/int = 0 + 1 + 2 + 3 == 6
        @perm.human_to_internal(10,4).should eql([6,4])
    end

    it "internal->human transform for 1+2+3+4" do
        @perm.internal_to_human(
            (1 << (1-1)) | (1 << (2-1)) | (1 << (3-1)) | (1 << (4-1))
        ).should eql([1,2,3,4])
    end

    it "internal->human transform for 7+9" do
        @perm.internal_to_human(
            (1 << (7-1)) | (1 << (9-1))
        ).should eql([7,9])
    end

    it "10/4 is 1,2,3,4" do
        (@perm.get_perms(*@perm.human_to_internal(10,4)).map {|x| @perm.internal_to_human(x) }).should eql([[1,2,3,4]])
    end

    it "get_perms(10/4)" do
        human_get_perms(@perm, 10, 4).should eql([[1,2,3,4]])
    end

    it "get_perms(3/2)" do
        human_get_perms(@perm, 3, 2).should eql([[1,2]])
    end

    it "get_perms(16/2)" do
        human_get_perms(@perm, 16, 2).should eql([[7,9]])
    end

    it "get_perms(7/3)" do
        human_get_perms(@perm, 7, 3).should eql([[1,2,4]])
    end

    it "gen_perms(25/5)" do
        human_get_perms(@perm, 25, 5).should eql([
            [1,2,5,8,9],
            [1,2,6,7,9],
            [1,3,4,8,9],
            [1,3,5,7,9],
            [1,3,6,7,8],
            [1,4,5,6,9],
            [1,4,5,7,8],
            [2,3,4,7,9],
            [2,3,5,6,9],
            [2,3,5,7,8],
            [2,4,5,6,8],
            [3,4,5,6,7],
        ])
    end
end



