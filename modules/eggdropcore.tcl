# Scripts-core for eggdrop

# included are:
#  alltools.tcl,v 1.15 2002/12/24 02:30:04 wcc

proc constructor {} {
	foreach p {
		putmsg putchan putnotc putact
		strlwr strupr strcmp stricmp strlen stridx
		iscommand timerexists utimerexists inchain randstring
		putdccall putdccbut killdccall killdccbut
		iso realtime testip number_to_number
		isnumber ispermowner matchbotattr ordnumber
	} {
		register_global $p 0
	}
}


# So scripts can see if allt is loaded.
set alltools_loaded 1
set allt_version 205

# For backward compatibility.
set toolbox_revision 1007
set toolbox_loaded 1
set toolkit_loaded 1

#
# toolbox:
#

proc putmsg {dest text} {
  puthelp "PRIVMSG $dest :$text"
}

proc putchan {dest text} {
  puthelp "PRIVMSG $dest :$text"
}

proc putnotc {dest text} {
  puthelp "NOTICE $dest :$text"
}

proc putact {dest text} {
  puthelp "PRIVMSG $dest :\001ACTION $text\001"
}

#
# toolkit:
#

proc strlwr {string} {
  string tolower $string
}

proc strupr {string} {
  string toupper $string
}

proc strcmp {string1 string2} {
  string compare $string1 $string2
}

proc stricmp {string1 string2} {
  string compare [string tolower $string1] [string tolower $string2]
}

proc strlen {string} {
  string length $string
}

proc stridx {string index} {
  string index $string $index
}

proc iscommand {command} {
  if {[string compare "" [info commands $command]]} then {
    return 1
  }
  return 0
}

proc timerexists {command} {
  foreach i [timers] {
    if {![string compare $command [lindex $i 1]]} then {
      return [lindex $i 2]
    }
  }
  return
}

proc utimerexists {command} {
  foreach i [utimers] {
    if {![string compare $command [lindex $i 1]]} then {
      return [lindex $i 2]
    }
  }
  return
}

proc inchain {bot} {
  islinked $bot
}

proc randstring {length {chars abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789}} {
  set count [string length $chars]
  for {set index 0} {$index < $length} {incr index} {
    append result [string index $chars [rand $count]]
  }
  return $result
}

proc putdccall {text} {
  foreach i [dcclist CHAT] {
    putdcc [lindex $i 0] $text
  }
}

proc putdccbut {idx text} {
  foreach i [dcclist CHAT] {
    set j [lindex $i 0]
    if {$j != $idx} then {
      putdcc $j $text
    }
  }
}

proc killdccall {} {
  foreach i [dcclist CHAT] {
    killdcc [lindex $i 0]
  }
}

proc killdccbut {idx} {
  foreach i [dcclist CHAT] {
    set j [lindex $i 0]
    if {$j != $idx} then {
      killdcc $j
    }
  }
}

#
# moretools:
#

proc iso {nick chan} {
  matchattr [nick2hand $nick $chan] o|o $chan
}

proc realtime {args} {
  switch -exact -- [lindex $args 0] {
    time {
      return [strftime %H:%M]
    }
    date {
      return [strftime "%d %b %Y"]
    }
    default {
      return [strftime "%I:%M %P"]
    }
  }
}

proc testip {ip} {
  set tmp [split $ip .]
  if {[llength $tmp] != 4} then {
    return 0
  }
  set index 0
  foreach i $tmp {
    if {(([regexp \[^0-9\] $i]) || ([string length $i] > 3) || \
         (($index == 3) && (($i > 254) || ($i < 1))) || \
         (($index <= 2) && (($i > 255) || ($i < 0))))} then {
      return 0
    }
    incr index
  }
  return 1
}

proc number_to_number {number} {
  switch -exact -- $number {
    0 {
      return Zero
    }
    1 {
      return One
    }
    2 {
      return Two
    }
    3 {
      return Three
    }
    4 {
      return Four
    }
    5 {
      return Five
    }
    6 {
      return Six
    }
    7 {
      return Seven
    }
    8 {
      return Eight
    }
    9 {
      return Nine
    }
    10 {
      return Ten
    }
    11 {
      return Eleven
    }
    12 {
      return Twelve
    }
    13 {
      return Thirteen
    }
    14 {
      return Fourteen
    }
    15 {
      return Fifteen
    }
    default {
      return $number
    }
  }
}

#
# other commands:
#

proc isnumber {string} {
  if {([string compare "" $string]) && \
      (![regexp \[^0-9\] $string])} then {
    return 1
  }
  return 0
}

proc ispermowner {hand} {
  global owner

  regsub -all -- , [string tolower $owner] "" owners
  if {([matchattr $hand n]) && \
      ([lsearch -exact $owners [string tolower $hand]] != -1)} then {
    return 1
  }
  return 0
}

proc matchbotattr {bot flags} {
  foreach flag [split $flags ""] {
    if {[lsearch -exact [split [botattr $bot] ""] $flag] == -1} then {
      return 0
    }
  }
  return 1
}

proc ordnumber {str} {
  if {[isnumber $str]} {
    set last1 [string range $str [expr [strlen $str]-1] end]
    set last2 [string range $str [expr [strlen $str]-2] end]
    if {$last1=="1"&&$last2!="11"} {
      return "[expr $str]st"
    } elseif {$last1=="2"&&$last2!="12"} {
      return "[expr $str]nd"
    } elseif {$last1=="3"&&$last2!="13"} {
      return "[expr $str]rd"
    } else {
      return "[expr $str]th"
    }
  } else {
    return "$str"
  }
}
