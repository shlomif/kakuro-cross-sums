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
    end
end
