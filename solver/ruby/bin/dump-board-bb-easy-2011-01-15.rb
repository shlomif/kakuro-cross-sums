require "kakuro-board.rb"

puts "Before new"
$BOARD = Kakuro::Board.new
puts "After new"
$BOARD.parse(<<'EOF')
[\]   [\]   [\]     [16\] [12\]    [\]   [\]      [23\] [18\]
[\]   [17\] [23\17] []    []       [22\] [\8]     []    []
[\34] []    []      []    []       []    [23\17]  []    []
[\17] []    []      [24\] [\30]    []    []       []    []
[\]   [\17] []      []    [23\16]  []    []       [16\] [\]
[\]   [21\] [24\16] []    []       [\10] []       []    [16\]
[\29] []    []      []    []       [17\] [16\16]  []    []
[\17] []    []      [\35] []       []    []       []    []
[\16] []    []      [\]   [\16]    []    []       [\]   [\]
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
    format = '[%-10s]'
    c = $BOARD.cell(pos)
    if c.solid?
        print sprintf(format, ' \\\\ ')
    else
        print sprintf(format, c.get_possible_verdicts.join(','))
    end
end
print "\n"
