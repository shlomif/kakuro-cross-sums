describe "System Test 1" do
    before do
        @got_output = `ruby bin/dump-board.rb`
    end

    it "should remain the same" do
        @got_output.should == <<'EOF'
Before new
After new
After parse
After prepare
After merge_constraints

[ \\       ][ \\       ][ \\       ][ \\       ][ \\       ][ \\       ][ \\       ][ \\       ][ \\       ]
[ \\       ][ \\       ][7,8       ][7,8       ][ \\       ][0         ][1         ][ \\       ][ \\       ]
[ \\       ][8         ][4         ][6,7       ][0         ][1         ][5         ][ \\       ][ \\       ]
[ \\       ][0         ][3         ][5         ][1         ][2         ][ \\       ][1         ][8         ]
[ \\       ][ \\       ][0         ][3         ][ \\       ][3         ][2         ][0         ][1         ]
[ \\       ][2         ][6         ][7,8       ][3         ][4,5       ][1,5       ][ \\       ][ \\       ]
[ \\       ][0         ][2         ][ \\       ][1,2,4,5   ][4,5       ][0         ][1,4,5     ][ \\       ]
[ \\       ][ \\       ][ \\       ][0,1       ][0,1,4     ][ \\       ][1,5       ][1,4,5,8   ][ \\       ]
[ \\       ][ \\       ][ \\       ][0,1       ][0,1       ][ \\       ][ \\       ][ \\       ][ \\       ]
EOF
    end
end
