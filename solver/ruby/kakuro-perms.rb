require "kakuro-perms-db.rb"

module Kakuro
    class Perms
        def human_to_internal(sum, num)
            return [sum-num, num]
        end

        def internal_to_human(bitmask)
            d = 1
            nums = Array.new
            while bitmask > 0 do
                if ((bitmask & 0x1) == 0x1)
                    nums.push(d)
                end
                bitmask >>= 1
                d += 1
            end
            return nums
        end

        def get_perms(sum, num)
            return (
                Kakuro::GENERATED_PERMS.has_key?(num) &&
                Kakuro::GENERATED_PERMS[num].has_key?(sum)
            ) ? Kakuro::GENERATED_PERMS[num][sum] : []
        end
    end
end
