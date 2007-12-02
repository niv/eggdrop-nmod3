# nmod2 dcc control module

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050327210128" }
		{ "description" "[core] dcc interface to nmod" }
	}
}
proc depends {} {
	return {
		{ core 20050328122600 }
	}
}

proc constructor {} {
	bind dcc n nmod3 dcc
	
#	cfg_create "str" "autoloadfile" "/home/eggheads/eggs/cr/nmod.autoload"
#	if {[file exists [cfg_get autoloadfile]]} {
#		log "autoloading all modules"
#		set f [open [cfg_get autoloadfile] r]; set d [read $f]; close $f
#		foreach mod [split $d "\n"] {
#			if {[string trim $mod] == ""} { continue }
#			log " -> loading '$mod'"
#			set r [::nmod::nmod_load $mod]
#			log [errtostr load [lindex $r 0] [lindex $r 1]]
#		}
#		log "done."
#	}
	
	return
}


# converts the error id to a descriptive error message
proc errtostr {pr errno {param ""}} {
	switch -- $pr {
		"load" {
			switch -- $errno {
				0 { return "Loaded successfully." }
				-1 { return "Module already loaded." }
				-2 { return "Module file not found or not readable: $param" }
				-3 { return "Evaluation/Source error: $param" }
				-4 { return "Missing procs in module: $param" }
				-5 { return "Invalid mod file or name: $param" }
				-6 { return "Dependancy failed: $param" }
				-7 { return "Error while calling constructor: $param" }
			}
		}
		"unload" {
			switch -- $errno {
				0 { return "Unloaded successfully." }
				-1 { return "Module not loaded." }
				-5 { return "Invalid mod file or name: $param" }
				-6 { return "Dependancy error: $param" }
			}
		}
		"cfg_set" {
			switch -- $errno {
				0 { return "Set." }
				-1 { return "Cannot set: $param" }
			}
		}
		default { return "Unknown error handler: $pr, unknown error: $errno - $param" }
	}
}



proc dcc {h i t} {
	set fa [string trim [lindex [split $t] 0]]
	set f0 [string trim [lindex [split $t] 1]]
	set f1 [string trim [lindex [split $t] 2]]
	set f2 [string trim [lindex [split $t] 3]]

	switch -- $fa {
		"autoload" {
			
		}

		"load" {
			set r [catch {::nmod3::load $f0} err]
			if {$r} {
				putidx $i [errtostr load $f0 [lindex $err 1]]
			}
		}

		"unload" {
			set r [catch {::nmod3::unload $f0} err]
			if {$r} {
				putidx $i [errtostr unload $f0 [lindex $err 1]]
			}
		}

		"reload" {
			set r [catch {::nmod3::unload $f0} err]
			if {$r} {
				putidx $i [errtostr unload $f0 [lindex $err 1]]
			}
			set r [catch {::nmod3::load $f0} err]
			if {$r} {
				putidx $i [errtostr load $f0 [lindex $err 1]]
			}
		}


		"list" {
			putidx $i "Loaded modules: [join [::nmod3::get_loaded] {, }]"
			return 1
		}
		
		"config" -
		"cfg" {
			if {$f0 == ""} {
				putidx $i "Syntax: cfg <mod> \[<key> <val>\]"
				return 1
			}
			set mod [::nmod::nmod_fqname $f0]
			if {![::nmod::nmod_is_loaded $mod]} {
				putidx $i "This module is not loaded."
				return 1
			}
			
			if {$f1 == ""} { ;# show all config values
				foreach k [::nmod::nmod_cfg_keys $mod] {
					set v [::nmod::nmod_cfg_get_full $mod $k]
					putidx $i [format "(%s) %s: %s" [lindex $v 0] [lindex $v 1] [lindex $v 2]]
				}
				return 1
			} {
				if {$f2 == ""} {
					putidx $i "Syntax: cfg <mod> <key> <val>"
					return 1
				} {
					# set the valuei
					set r [::nmod::nmod_cfg_set $mod $f1 [join [lrange [split $t] 3 end]]]
					putidx $i [errtostr cfg_set [lindex $r 0] [lindex $r 1]]
					return 1
				}
			}
		}
		
		"kill" -
		"forceremove" {
			if {$f0 == ""} {
				putidx $i "Syntax: kill <mod>"
				return 1
			}
			::nmod::nmod_forceremove [::nmod3::kill $f0]
			putidx $i "Done."
		}


		default {
			putidx $i "nmod3"
			putidx $i "  Copyleft 2005 by Elven <elven@elven.de>"
			putidx $i ""
			putidx $i "Syntax: nmod list"
			putidx $i "             load <module>"
			putidx $i "             unload <module>"
			putidx $i "             reload <module>"
			putidx $i "             kill <module>"
			return 0
		}

	}
}
