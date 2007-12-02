# stringtools.tcl
# by Elven
# GNU/GPL

proc constructor {} {
	register_global countchars
	register_global countbetween
	register_global rxsplit
	register_global timedesc2int
	register_global parseParam
}

##########################################
# code below :)
###

# Splits a string with a given
# regexp. Returns a list.
#
# Examples:
#   rxsplit "a b  plenk  dengong" " +"
#    => {a} {b} {plenk} {dengdong}
#   rxsplit "ab  aaac" {[b ]+}
#     => {a} {aaac}
#   rxsplit "frrrrd" {r}
#     =>  {f} {} {} {} {d}
#   rxsplit "frrrrd" {r+}
#     =>  {f} {d}
proc rxsplit {str rx} {
	set results [list]
	while {[regexp "^(.*?)${rx}(.*)$" $str {} start en]} {
		lappend results $start
		set str $en
	}
	if {![regexp "^${rx}$" $str]} { lappend results $str }
	return $results  
}

# Counts the occurences of
# a char. Returns int.
#
# Example:
#  countchars "abbba" a => 2
proc countchars {str char} {
	set cnt 0
	for {set i 0} {$i < [string length $str]} {incr i} {
		if {[string index $str $i] == [string index $char 0]} {
			incr cnt
		}
	}
	return $cnt
}

# Counts the chars between
# two occurences of given char
# or the string end.
#
# Examples:
#  countbetween "abbbb" a => 4
#  countbetween "abbaa" a => 2
#  countbetween "abbaa" b => 0
proc countbetween {str char} {
	set is 0; set cnt 0
	for {set i 0} {$i < [string length $str]} {incr i} {
		if {[string index $str $i] == [string index $char 0]} {
			if {$is} { set is 0 } { set is 1 }
			continue
		}
		if {$is} { incr cnt }
	}
	return $cnt
}

# Converts a timedesc timestamp
# to an integer value.
# Possible units:
#  d(ay(s)), m(inute(s)), h(our(s)), s(econd(s))
#
# Examples:
#  1m3s to 63 (seconds)
#  4 hours 50 minutes 1 second
#
# Returns:
#    -1 on parse failure
#  > -1 on success
proc timedesc2int str {
	if {![regexp {^(?:(\d+) ?d(?:ays?)?)? ?(?:(\d+) ?h(?:ours?)?)? ?(?:(\d+) ?m(?:inutes?)?)? ?(?:(\d+) ?s(?:econds?)?)?$} $str "" days hours minutes seconds]} {
		return -1
	}
	if {$days == "" && $hours == "" && $minutes == "" && $seconds == ""} {
		return -1
	}
	if {$seconds == ""} { set seconds 0 }
	if {$minutes == ""} { set minutes 0 }
	if {$hours   == ""} { set hours   0 }
	if {$days    == ""} { set days    0 }
	return [expr $seconds + $minutes * 60 + $hours * 3600 + $days * 3600 * 24]
}

# Converts an integer
# into a timedesc timestamp.
# Example:
#   128 -> 2m8s
proc int2timedesc int {
	# Highest field: days
	while {$int - 3600*24 > 3600*24} {
		incr int [expr -(3600*24)]
	}
}

# Parses parameters as bash would do
# supply a string
proc parseParam {str {cutOff 0}} {
	set res [list]
	set currentParam ""
	set inQuote 0
	for {set i 0} {$i < [string length $str]} {incr i} {
		if {$cutOff > 0 && [llength $res] == $cutOff-1} {
			set currentParam [string trim [string range $str $i end]]
			if {[string trim $currentParam] != ""} {
				lappend res $currentParam
			}
			return $res
		}
		set c [string index $str $i]
		if {$c == " "} {
			if {!$inQuote} {
				if {[string trim $currentParam] != ""} {
					lappend res $currentParam
				}
				set currentParam ""
			} else {
				append currentParam $c
			}
		} elseif {$c == "\"" && [string index $str $i-1] != "\\"} {
			if {1 == $inQuote} { set inQuote 0 } { set inQuote 1 }
			if {[string trim $currentParam] != ""} {
				lappend res $currentParam
			}
			set currentParam ""
		} else {
			append currentParam $c
		}
		
	}
	if {[string trim $currentParam] != ""} {
		lappend res $currentParam
	}
	return $res
}
