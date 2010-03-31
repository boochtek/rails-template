# Idea from Ben Mabey (http://www.ruby-forum.com/topic/140743#625276)
# Allows these kinds of code to read more clearly:
#   running { 1/0 }.should raise_error
#   running { team.add_player(player) }.should change(roster, :count).by(1)
#   string = 'string'; running { string.reverse! }.should change { string }.from("string").to("gnirts")

alias :running :lambda
