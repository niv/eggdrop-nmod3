depend_on "cqac"
depend_on "stringtools"


proc constructor {} {
	bind pub "-" "ntcl" pub
}

# This returns the FIRST nick that is authed to the specified auth name.
# Beware.
proc auth2nick {auth} {
	foreach chan [channels] {
		foreach nick [chanlist $chan] {
			if {[strlwr [getchanlogin $nick]] == [strlwr $auth]} {
				return $nick
			}
		}
	}
	return ""
}

proc pub {n u h c t} {
#	if {[getchanlogin $n] != "elven"} {
#		putmsg $c "Du ($n == [getchanlogin $n]) darfst nich!"
#		return
#	}

	set starts [clock second]; set start [clock clicks]
	
	set errnum [catch {namespace eval tclspace $t} error]
	#set errnum [catch {eval $args} error]
	
	set end [clock clicks]; set ends [clock second];
	
	set error [split $error "\n"]
	
	if {[expr $ends - $starts] > 1} {
		set rx "[expr $ends - $starts] seconds, [llength $error] lines."
	} {
		set rx "[expr $end - $start] clicks, [llength $error] lines."
	}
	
	if {$error == ""} { set error "--" }
	
	for {set i 0} {$i < [llength $error]-1} {incr i} {
		if {$i >= 20} {
			putmsg $c " -- Truncated after 20 lines of output"
			break
		}
		putmsg $c "[lindex $error $i]"
	}
	putmsg $c "[lindex $error end] - $rx"
	
	return
}
