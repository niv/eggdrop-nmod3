# This is the dice management module.

# Triggers on:
# Command: !d <..>
# Action: /me attacks a monster [!d 1d4]  || ONLY at the end of the line

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050327210128" }
		{ "description" "dicebot" }
	}
}

proc constructor {} {
	global nextCheat nextCheatNick
	set nextCheat 0
	set nextCheatNick ""
	bind pubm - "*" pubdice
	bind ctcp - "ACTION" ctcpdice
	bind dcc  n "dicecheat" dccdice
}

proc destructor {} {
}

proc dccdice {h i t} {
	global nextCheat nextCheatNick
	set a [split $t " "]
	set nick [lindex $a 0]
	set dice [lindex $a 1]
	set nextCheat $dice
	set nextCheatNick $nick
	putlog "DiceCheat: $t on"
}

proc ctcpdice {n u h d k t} {
	if {[isbotnick $d]} { return }
	pubdice $n $u $h $d $t
}


proc pubdice {n u h c t} {
	global defdie
	set a [lindex [split $t] 0]
	if {$a == "!setd" || $a == "!setdie"} { ;# !setdie 5d20
		set d [lindex [split $t] 1]
		if {$d == ""} { set d "1d20" }
		set r [regexp -all -inline {(\d+)?([DWdwSs])(\d+)((\+|-)(\d+))?} $d]
		if {$r == ""} {
			putmsg $c "Invalid default die: $d"
			return
		}
		set defdie($c) $r
		putmsg $c "Okay, default die for $c is now: $d"
		return
	}
	
	if {$a == "!d" || $a == "!dice" || $a == "!w" || $a == "!wuerfel"} {
		doDice $c [join [lrange [split $t] 1 end]] $n
		return
	}
	
	set r [regexp -inline -- {\s\[?!d(?: ([\ddDwWsS ]+?)|)\]?$} $t]
	if {$r == ""} { return }
	#set rx [regexp -inline {(\d+)?([DWdwSs])(\d+)((\+|-)(\d+))?} $t]
	#if {$rx == ""} { return }
	doDice $c [lindex $r 1] $n
	return
}


proc doDice {t l {nicky ""}} {
	global defdie nextCheat nextCheatNick
	set r [regexp -all -inline {(\d+)?([DWdwSs])(\d+)((\+|-)(\d+))?} $l]

	if {$r == ""} {
		#putmsg $t "Invalid Format. Try \"\[x\]d\[xx\]\[+|-x\]\". You may specify subsequent rolls. For example: !$m 3d20+1 4d6"
		#return
		if {[info exists defdie($t)]} {
			set r $defdie($t)
		} {
			set r [list "1d20" 1 "d" 20 "" "" ""]
		}
	}

	if {[llength $r] < 6 || [llength $r] > 30} {
		putmsg $t "Total rolls should be between 1 and 5."
		return
	}

	set globtotal 0
	set rolls 0

	foreach {all count key size crap mode modeval} $r {
		incr rolls
		switch -exact -- $key {
			"s" {
				set key "s"
			}
			"S" {
				set key "s"
			}
			default {
				set key "d"
			}
		}
		if {$count == ""} {
			set count 1
		}
		#if {$mode == ""} { set mode "+" }
		#if {$modeval == ""} { set modeval "0" }
		
		set all "${count}${key}${size}${mode}${modeval}"
		
		if {$count < 1 || $count > 10000} {
			putmsg $t "$all: Dice count should be between 1 and 10000.";
			return
		}
		if {$size < 2 || $size > 500} {
			putmsg $t "$all: Dice size should be between 2 and 500."; 
			return
		}
		set str "$all:" 
		set total 0
		set rl [list]
		
		#roll all dices and add them
		for {set i 0} {$i < $count} {incr i} {
			#putlog "cmp '$nextCheatNick' '$nicky'"
			if {$nextCheat != 0 && [string tolower $nextCheatNick] == [string tolower $nicky]} {
				#puts "going nextCheat"
				set v $nextCheat
				set nextCheatNick ""
				set nextCheat 0
			} {
				#putlog "going normal"
				set v [expr 1+[rand $size]]
			}
			lappend rl $v
			incr total $v
		}
		
		if {$key == "s"} {
			set rl [lsort -integer -increasing $rl]
			set final [list]
			set currentNum [lindex $rl 0]
			set currentCount 1
			for {set i 1} {$i < [llength $rl]} {incr i} {
				if {[lindex $rl $i] != $currentNum} {
					if {$currentCount != 1} {
						lappend final "${currentNum}x${currentCount}"
					} else {
						lappend final "$currentNum"
					}
					set currentNum [lindex $rl $i]
					set currentCount 1
					continue
				}
				incr currentCount
			}
			set rl $final
		}
		
		#build the output string, truncate after 20
		for {set i 0} {$i < [llength $rl]} {incr i} {
			if {$i < 20} {
				append str " [lindex $rl $i]"
			} 
			if {$i == 20 && [llength $rl] != 20} {
				append str " (..)"
			}
		}
		
		if {$mode != ""} {
			append str " $mode$modeval"
			if {$mode == "+"} { incr total $modeval } { incr total -$modeval }
		}
		if {$count > 1 || $mode != ""} { append str " = $total" }
		putmsg $t $str
		incr globtotal $total
	}

	#if {$rolls > 1} { putmsg $t " = $globtotal" }
}
