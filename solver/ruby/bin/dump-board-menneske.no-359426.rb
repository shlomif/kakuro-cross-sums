require "kakuro-board.rb"

puts "Before new"
$BOARD = Kakuro::Board.new
puts "After new"
$BOARD.parse(<<'EOF')
[\]     [17\]       [16\]       [7\]        [\]     [\]     [\]     [\]
[\19]   []          []          []          [\]     [\]     [16\]   [3\]
[\17]   []          []          []          [29\]   [4\11]  []      []
[\]     [\]         [\23]       []          []      []      []      []
[\]     [\]         [\]         [16\10]     []      []      [\]     [\]
[\]     [3\]        [17\16]     []          []      [6\]    [\]     [\]
[\23]   []          []          []          []      []      [16\]   [17\]
[\11]   []          []          [\]         [\19]   []      []      []
[\]     [\]         [\]         [\]         [\18]   []      []      []
EOF

puts "After parse"
$BOARD.prepare()
puts "After prepare"
while $BOARD.merge_constraints() or $BOARD.filter_constraints_without_cells()
    true
end
puts "After merge_constraints"
$BOARD.all_coords.each do |pos|
    if (pos.x == 0)
        print "\n"
    end
    format = '[%-6s]'
    c = $BOARD.cell(pos)
    if c.solid?
        print sprintf(format, ' \\\\ ')
    else
        print sprintf(format, c.get_possible_verdicts.map { |x| x+1 }.join(','))
    end
end
print "\n"
