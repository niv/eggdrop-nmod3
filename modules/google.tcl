#google module

#if {[info exists ::flood(google)]} { putmsg $t "Don't flood."; return }
#set ::flood(google) [unixtime]
#utimer 5 [list unset ::flood(google)]
#putmsg $t "Hereby we kindly ask you to bear with us while we are adjusting to googles website modifications."
#return

depend_on http


proc constructor {} {
	bind pub - "!google" gooogle
	bind pub - "!g" gooogle
}

proc gooogle {n u h c t} {
	set args [subst -nobackslashes -nocommands -novariables $t]
	set arg [split $args]
	set agent "Mozilla"
	if {[llength $arg] == 0} {
		putmsg $c "Please specify a search term."
		return
	}
	set query "http://www.google.de/search?btnI=&q="
	for {set index 0} {$index < [llength $arg]} {incr index} {
		set query "$query[lindex $arg $index]"
		if {$index < [llength $arg] - 1} {
			set query "$query+"
		}
	}
	
	set token [http_head $query 2000]
	set headers [lindex $token 0]
	foreach {name value} $headers {
		if {[regexp -nocase ^Location$ [string trim $name]]} {
			set newurl [string trim $value]
			putmsg $c "$n: $newurl"
			return
		}
	}
	putmsg $c "$n, no results. Search yourself ( http://www.google.com/ ) or use other search terms."
}
