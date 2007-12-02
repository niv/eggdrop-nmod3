# userdefined blocks support for tcl

proc constructor {} {
	register_global yield 0
	
	register_global times 0
	
	register_global leach 0
	register_global lcompact 0
	
	register_global aeach 0
}

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050330154600-0.9" }
		{ "description" "[core] support for userdefined blocks (ruby-alike)" }
	}
}

# Runs `block` with each parameter in `args` extended.
# Note that this is only useful for creating new control
# structures; it won't even work on level 0!
# Returns: the block result
proc yield {block args} {
	foreach a $args {
		upvar $a $a
		uplevel 2 [list set $a [set $a]]
	}
	set result [uplevel 2 $block]
}


# Runs `block` for each element in the list `l`.
# Replaces the element with the returned value.
# Element: $vn
# Returns: the (new) list
# Modifies: l if inplace is 1
proc leach {l block {vn "e"} {inplace 0}} {
	if {$inplace} { upvar l ls } { set ls $l }
	for {set i 0} {$i < [llength $ls]} {incr i} {
		set $vn [lindex $ls $i]
		set r [yield $block $vn]
		if {$r != ""} {
			lset ls $i $r
		}
	}
	return $ls
}

# Runs `block` `times` times.
# Returns: nuffink
proc ltimes {times block} {
	for {set ix 0} {$ix < [expr int($times)]} {incr ix} {
		yield $block
	}
	return
}

# Runs `block` for each element in the list `l`,
# building a new list on the way.
# Appends e to the resulting list ONLY 
# if the block returns 0.
# Element: $vn
# Returns: the new list
proc lcompact {l block {vn "e"}} {
	set l [list]
	foreach e $li {
		set r [yield $block e]
		if {$r == 0} {
			lappend l $e
		}
	}
	return $l
}

# Runs `block` for each key->value pair in the array `a`.
# Elements: key, value
# Returns: nothing
proc aeach {a block {key "key"} {value "value"}} {
	error "aeach is disfunctional at the moment"
	foreach $key [array names a] {
		set $value $a([set $key])
		yield $block $key $value
	}
	return
}
