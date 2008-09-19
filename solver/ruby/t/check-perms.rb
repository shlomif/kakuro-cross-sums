require "kakuro-perms.rb"

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

end
