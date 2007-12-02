# the dcc interface
# nmod2 dcc control module

namespace eval ::nmod3::core {
	bind dcc n nmod3 ::nmod3::core::dcc
	
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
				::nmod3::kill $f0
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
	
	
	if {[info exists nmod(autoload)] && 0 < [llength $nmod(autoload)] && ![info exists nmod(autoloaddone)]} {
		log "Auto-loading modules.."
		foreach a $nmod(autoload) {
			set r [catch {load $a} e]
			if {$r} {
				log " Failed loading $a: $e" {} e
			}
		}
		log "Done."
	}
}

