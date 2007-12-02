
depend_on stringtools

proc constructor {} {
	bind pub - !remind remynd
	bind pub - !date   dyte
}

proc dyte {n u h c t} {
	if {$t == ""} {
		putmsg $c [clock format [clock seconds]]
	} {
		putmsg $c [clock format [clock seconds] -format $t]
	}
}

proc remynd {n u h c t} {
	set l $t
	set t $c
	if {[regexp {^(?:(.+) (?:at|in)|at|in) (.+?)(?: (that|to|about) (.+?))?(?: (in private))?$} $l {} to time prefix what priv]} {
		set delay [timedesc2int $time]
		if {$delay < 0} {
			set r [catch {clock scan $time} delay]
			if {$r} {
				putmsg $t "Error: $delay"
				# return
			}
			if {![string is integer $delay]} {
				putmsg $t "Invalid time specification. Use '!remind' for help."
				return
			}
			set delay [expr $delay - [unixtime]]
			if {$delay < 1} { 
				putmsg $t "That time specification has already expired."
				return
			}
			if {$delay > 60*60*24*3000} {
				putmsg $t "Be reasonable."
				return
			}
			#putmsg $t "I would remind you in $delay seconds, string used: $time"
			#return
		}
		
		if {$to == ""} { set to "me" }
		if {$to == "me" || $to == $n} { set tx $n } { set tx $to }
		if {![onchan $tx $c]} { putmsg $t "I can't see $tx here, can you?"; return }
		if {$to == "me" || $to == $n} {
			utimer $delay [list putmsg $t [string trim "$tx, you asked me to remind you $prefix $what"]]
		} {
			utimer $delay [list putmsg $t [string trim "$tx, $n asked me to remind you $prefix $what"]]
		}
		putmsg $t "Okay, will do."
		return
	}


	putmsg $t "Syntax: \"remind (\[me\]|nickname) in (XXdXXhXXmXXs)|at (mm/dd/yyyy hh:nn:ss) \[ (that|to|about) sth\]\""
	putmsg $t " Examples:   remind in 5s  ||  remind MrAnonymous in 2 hours 20 minutes to make a phone call"
	putmsg $t "   remind me at 12:43 about something || remind MrAnonymous at 12/11/2004 14:13:12 that its time"
}
