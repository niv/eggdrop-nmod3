#rejoinban.tcl
#bans auto-rejoiner

#todo: check ban hosts & removal

#####################
# settings

global rejoinban
global rejoinbans

set rejoinban(fudge) 5
	#time between kick & join in seconds to be considered auto-rejoin
	
set rejoinban(bantime) 10
	#minutes
	
set rejoinban(msg) "Thou shalt not auto-rejoin."



proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20061030190501" }
		{ "description" "bans people who rejoin on kick" }
	}
}


proc constructor {} {
	setudef flag rejoinban
	bind kick "-" "*" ev_kick
	bind join "-" "*" ev_join
}

proc destructor {} {
}

catch { unset rejoinbans }

proc ev_kick {n u h c t r} {
	global rejoinbans
	global rejoinban
	if {[isbotnick $t]} { return 0 } ;#dont ban ourselves!
	if {![channel get $c rejoinban]} { return 0 }
	if {[isop $t $c]} { if {[channel get $c dontkickops]} { return 0 } }
	set c [string tolower $c]
	set t [string tolower $t]
	set rejoinbans($t:$c) 1
	utimer $rejoinban(fudge) [list ev_timer $t $c]
}

proc ev_timer {n c} {
	global rejoinbans
	if {[info exists rejoinbans($n:$c)]} {
		unset rejoinbans($n:$c)
	}
}

proc ev_join {n u h c} {
	if {[isbotnick $n]} { return 0 } ;#as we said above.
	global rejoinban
	global rejoinbans
	set c [string tolower $c]
	set n [string tolower $n]
	if {![channel get $c rejoinban]} { return 0 }
	if {![info exists rejoinbans($n:$c)]} { return 0 }
	newchanban $c [maskhost $u] "rejoinban" $rejoinban(msg) $rejoinban(bantime)
	unset rejoinbans($n:$c)
}
