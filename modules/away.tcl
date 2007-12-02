#away.tcl
#by Elven <elven@elven.de>

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050327210128" }
		{ "description" "auto-away on connect" }
	}
}

proc constructor {} {
  cfg_create str reason "Im a bot."
  bind evnt "-" "init-server" away:init
  return
}

proc event {t r} {
  if {$t == "cfg_set" && [lindex $r 0] == "reason"} {
    log "Config was changed - setting new away-reason"
    putserv "AWAY :[lindex $r 1]"
  }
}

proc away:init {t} {
  putserv "AWAY :[cfgget reason]"
}
