# nmod port of votools.tcl
# CopyLeft 2003 by Elven
# GNU/GPL

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050327210128" }
		{ "description" "autovoice/autoop/voicebitch" }
	}
}

proc constructor {} {
	setudef flag avoice
	setudef flag vbitch
	setudef flag aop
	bind join - "#* *" join
	bind mode - "#* +v" vbitch
	return
}

proc join {n u h c} {
  if {![botisop $c]} { return }
  if {[channel get $c avoice]} {
    if {![channel get $c vbitch]} {
      pushmode $c "+v" $n
    }
  }
  if {[channel get $c aop]} {
    if {![channel get $c bitch]} {
      pushmode $c "+o" $n
    }
  }
  return
}

proc vbitch {n u h c m v} {
  if {![botisop $c]} { return }
  if {![channel get $c vbitch]} { return }
  if {$n == $::botnick} { return }
  if {![matchattr [nick2hand $v] "v|v" $c]} {
    pushmode $c "-v" $v
  }
  return
}

#You open one of the 1002 boxes on this floor and find...
# A cookbook with recipes for a number of fantastic beings, including halflings, dwarfs, dragons, orcs, and goblins.
# It is written in elvish.
