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
class KakuroPermutations

    def initialize()
        @min_digit = 0
        @max_digit = 8
    end

    def get_permutations_from(start, sum, num_places)
        if num_places == 1
            if (sum >= start) && (sum <= @max_digit)
                return [[sum]]
            else
                return []
            end
        end

        results = []
        (start .. [@max_digit, sum].min).each do |first|
            results +=
                get_permutations_from(
                    first+1, sum-first, num_places-1
                ).map {|rest| [first, *rest]}
        end
        return results
    end

    def get_permutations(sum, num_places)
        return get_permutations_from(@min_digit, sum, num_places)
    end

    def get_min_sum(num_places)
        return ((@min_digit + @min_digit + num_places - 1) * num_places / 2).to_i
    end

    def get_max_sum(num_places)
        return ((@max_digit + @max_digit - (num_places - 1)) * num_places / 2).to_i
    end

    def perm_to_bitmask(perm)
        return perm.inject(0) {|total, x| (total | (1 << x)) }
    end

    def generate_file(filename)
        fh = File.new(filename, "w")
        fh.puts("module Kakuro");
        fh.puts("\tGENERATED_PERMS = {");
        (1 .. (@max_digit - @min_digit + 1)).each do |num_places|
            fh.puts(num_places.to_s + " => {")
            (get_min_sum(num_places) .. get_max_sum(num_places)).each do |sum|
                fh.puts(sum.to_s + " => [" +
                        get_permutations(
                            sum, num_places
                        ).map{|x| perm_to_bitmask(x).to_s }.join(",") +
                        "],"
                       );
            end
            fh.puts("},")
        end
        fh.puts("};")
        fh.puts("end")
        fh.close()
    end
end

KakuroPermutations.new.generate_file(ARGV.shift);

