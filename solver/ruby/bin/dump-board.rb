require "kakuro-board.rb"

puts "Before new"
$BOARD = Kakuro::Board.new
puts "After new"
$BOARD.parse(<<'EOF')
[\]    [\]      [29\]  [34\]   [\]      [21\]  [8\]     [\]    [\]
[\]    [10\17]  []     []      [3\3]    []     []       [\]    [\]
[\30]  []       [5]    []      []       [2]    []       [3\]   [11\]
[\16]  []       []     [6]     []       [3]    [12\11]  []     []
[\]    [4\5]    []     []      [13\10]  []     []       []     []
[\34]  []       [7]    []      [4]      []     []       [11\]  [\]
[\4]   []       []     [3\12]  []       []     [1]      []     [\]
[\]    [\]      [\6]   []      []       [\11]  []       []     [\]
[\]    [\]      [\3]   []      []       [\]    [\]      [\]    [\]
EOF
puts "After parse"
$BOARD.prepare()
puts "After prepare"
$BOARD.merge_constraints()
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
STDERR.puts($BOARD)
