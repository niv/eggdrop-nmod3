# stringtools.tcl
# by Elven
# GNU/GPL

proc constructor {} {
	register_global dec2bin
}

##########################################
# code below :)
###


proc bin2dec {b} {
	
}

proc dec2bin {x} {
	set r [list]
	#0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	set x2 $x
	set log2 0
	while {$x2 >= 2} {
		set x2 [expr $x2 / 2]
		set log2 [expr $log2 + 1]
	}
	for {set l2 $log2} {$l2 >= 0} {incr l2 -1} {
		while {[llength $r] < [expr 1+$l2]} { ;# pad the result with zeros for lset to work
			lappend r 0
		}
		set pow [expr pow(2, $l2)]
		if {$x >= $pow} {
			lset r $l2 1
			set x [expr $x - $pow]
		} else {
			lset r $l2 0
		}
	}
	return [join $r ""]
}
