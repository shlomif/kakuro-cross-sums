#--
# Copyright (c) 2011 Shlomi Fish
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require 'lib/kakuro_solver/perms_db'

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
