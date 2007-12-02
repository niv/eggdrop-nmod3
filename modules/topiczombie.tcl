#topicappend

set topiczombie(msgs) {
	"with a zombie"
#	"with feathers"
#	"without light"
#	"overly enjoyable"
#	"being adhered"
}

proc constructor {} {
	setudef flag topiczombie
	bind topc "-" "*" topic
}

proc topic {n u h c t} {
	global topiczombie ; if {$n == $::botnick} { return }
	if {![isop $::botnick $c]} { return }
	if {![channel get $c topiczombie]} { return }
	if {[string trim $t]==""} { return }
	set msg [join [lindex $topiczombie(msgs) [rand [llength $topiczombie(msgs)]]]]
	foreach x $topiczombie(msgs) {
		if {[string match "* $x" [string trim $t]]} { return }
	}
	putserv "TOPIC $c :$t $msg"
}
