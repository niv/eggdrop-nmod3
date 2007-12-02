#nmod3 slaves


namespace eval ::nmod3 {
	proc s_depend_on {name mod {ver -1}} {
		variable loaded
		variable depends
		if {$mod eq $name} { return }
		
		if { -1 < [lsearch -exact [array names loaded] $name] } {
			error "you cannot depend on modules after initialisation"
		}
		if {$mod == "core"} {
			return
		}
		if { -1 == [lsearch -exact [array names loaded] $mod] } {
			log "Dependancy: $mod, trying to autoload.." $name
			set r [catch {load $mod} e]
			if {$r} {
				log "  Failed.." $name e
				error "Dependancy failed: depending on $mod, but not loaded"
			}
		} {
			log "Dependancy: $mod, passed.." $name
		}
		lappend depends($name) [list $mod $ver]
		return
	}

	proc s_putlog {name args} {
		if {[llength $args] > 2} { error "wrong # of args: should be \"putlog text ?level?\"" }
		log [lindex $args 0] $name [lindex $args 1]
	}

	proc s_putcmdlog {name args} {
		putcmdlog "\[$name\] [lindex $args 0]"
	}
	
	proc s_putidx {name i t} {
		putidx $i "\[$name\] $t"
	}
	
	proc s_bind {name type flags cmd {procname ""}} {
		variable binds
		variable nmod
		if {$procname != ""} {
			set path "::nmod3::${name}::${procname}"
			
			if {[lsearch -exact $nmod(nonstackables) $type] != -1 && \
				[bind $type $flags $cmd] != "" && \
				[lsearch -exact $binds($name) [list $name $type $flags $cmd $procname]] == -1 \
			} {
				log "bind: $type $flags $cmd $procname -> failed (owned by someone else already)" $name d 1
				error "you are not allowed to overwrite other modules binds"
			}
			
			set res [::bind $type $flags $cmd $path]
			
			namespace eval ::nmod3::${name} { variable name }
			
			proc ::nmod3::${name}::${procname} {args} {
				set name [lindex [split [namespace current] "::"] end]
				set procname [lindex [split [info level [info level]] " "] 0]
				set procname [lindex [::nmod3::fsplit $procname "::"] end]
				set r [catch {
					$name eval [concat [list ${procname}] $args]
				} e]
				if {$r} {
					::nmod3::m_handle_bind_error $name $procname $e
				}
			}
			
			lappend binds($name) [list $type $flags $cmd $procname]
			
			log "bind: $type $flags $cmd $procname" $name d
			return $res
		} {
			return [::bind $type $flags $cmd]
		}
	}
	
	proc s_unbind {name type flags cmd procname} {
		variable binds
		set path $procname
		set procname [lindex [split $procname "::"] end]
		
		set i [lsearch -exact $binds($name) [list $type $flags $cmd $procname]]
		if {$i == -1} {
			log "unbind: $type $flags $cmd $procname -> failed (not his own)" $name d 1
			error "no such binding"
		}
		
		set res [::unbind $type $flags $cmd "::nmod3::${name}::${procname}"]
		set binds($name) [lreplace $binds($name) $i $i]
		namespace eval "::nmod3::${name}" "rename $procname \"\""
		log "unbind: $type $flags $cmd $procname" $name d
		return $res
	}

	# Returns the modules' binds
	proc s_binds {name typemask} {
		variable binds
		return [set binds($name)]
	}
	
	proc s_callbind {name bind args} {
		var loaded
		var binds
		var custombinds
		log "Calling bind ${bind}" $name d 1
		if { -1 == [lsearch $custombinds($name)] $bind } {
			error "not one of your bind types"
		}
		
		foreach mod [array names loaded] {
			foreach b $binds($mod) {
				if {[lindex $b 0] == $bind} {
					log "Calling $bind: [join $b " "]" $mod d 1
					set r [catch {$mod eval [concat [list [lindex $b end]] $args]} e]
					if {$r} {
						log "[join $b " "]: $e" $mod e
					}
				}
			}
		}
		return
	}
	
	proc s_register_global {name proc {trulyglobal 1}} {
		variable loaded
		variable globs
		log "register_global: $proc" $name d
		
		# commented out, because mods will want to register before defining
		#if {[$name eval info proc $proc] == ""} {
		#	error "procedure does not exist"
		#}
		
		if {1 == $trulyglobal && [info proc ::${proc}] != ""} {
			error "procedure-name already in global namespace"
		}
		
		namespace eval ::nmod3::${name} { variable name }
		
		proc ::nmod3::${name}::${proc} {args} {
			set name [lindex [split [namespace current] "::"] end]
			set procname [lindex [split [info level [info level]] " "] 0]
			set procname [lindex [::nmod3::fsplit $procname "::"] end]
			${name} eval [concat [list ${procname}] $args]
		}
		
		if {1 == $trulyglobal} {
			namespace eval ::nmod3::${name} "namespace export $proc"
			namespace eval :: "namespace import ::nmod3::${name}::${proc}"
		}
		
		foreach mod [array names loaded] {
			if {$mod == $name} { continue }
			$mod alias $proc "::nmod3::${name}::${proc}"
		}
		
		lappend globs($name) $proc
		return $proc
	}

	proc s_deregister_global {name proc} {
		variable loaded
		variable globs
		log "deregister_global: $proc" $name d
		
		foreach mod [array names loaded] {
			if {$mod == $name} { continue }
			$mod alias $proc {}
		}
		
		if {[info proc "::${proc}"] != ""} { ;# only if it was a true global
			namespace eval "::" "namespace forget ::nmod3::${name}::${proc}"
		}

		namespace eval "::nmod3::${name}" "rename $proc \"\""
		
		set i [lsearch $globs($name) $proc]
		if {-1 == $i} {
			error "nmod3: internal error: $proc not in globs list"
		}
		set globs($name) [lreplace $globs($name) $i $i]
		return $proc
	}
	
	
	proc s_register_bind {name type} {
		variable nmod
		variable custombinds
		if {![regexp {^[a-z]{3,4}$} $type]} { error "invalid type" }
		if {[lsearch $nmod(allbinds) $type] != -1} { error "you cannot overwrite eggdrop-binds" }
		
		foreach mod [array names custombinds] {
			if {[lsearch $custombinds($mod) $type] != -1} {
				if {$name == $mod} {
					error "already registered"
				} {
					error "already registered by someone else"
				}
			}
		}
		
		lappend custombinds($name) $type
		return $type
	}
	
	proc s_deregister_bind {name type} {
		variable custombinds
	}
	
	
	
	proc s_timer {name delay command} {
		variable timers
		log "timer started: \[\"[join $command {", "}]\"\]" $name d 1
		set tid [::timer $delay [list ::nmod3::m_ontimer $name $command]]
		log " -> $tid" $name d 1
		lappend timers($name) [list $delay $command $tid]
	}

	proc s_utimer {name delay command} {
		variable utimers
		log "utimer started: \[\"[join $command {", "}]\"\]" $name d 1
		set tid [::utimer $delay [list ::nmod3::m_onutimer $name $command]]
		log " -> $tid" $name d 1
		lappend utimers($name) [list $delay $command $tid]
	}
	
	proc s_killtimer {name tid} {
		variable timers
		if {![regexp {^timer\d+$} $tid]} { error "argument is not a timerID" }
		set found 0
		foreach t $timers($name) {
			if {[lindex $t 2] == $tid} {
				set found 1
			}
			incr bc
		}
		if {!$found} { error "invalid timerID: not owned by you" }
		log "timer killed: $tid" $name d 1
		return [killtimer $tid]
	}
	
	proc s_killutimer {name tid} {
		variable utimers
		if {![regexp {^timer\d+$} $tid]} { error "argument is not a timerID" }
		set found 0
		foreach t $utimers($name) {
			if {[lindex $t 2] == $tid} {
				set found 1
			}
			incr bc
		}
		if {!$found} { error "invalid timerID: not owned by you" }
		log "utimer killed: $tid" $name d 1
		return [killutimer $tid]
	}
	
	proc timers_is_in {name tid} {
		variable timers
		foreach t $timers($name) {
			if {[lindex $t 2] eq $tid} { return 1 }
		}
		return 0
	}
	proc utimers_is_in {name tid} {
		variable utimers
		foreach t $utimers($name) {
			if {[lindex $t 2] eq $tid} { return 1 }
		}
		return 0
	}	
	
	proc s_timers {name} {
		variable timers
		set t [::timers]
		set res {}
		foreach tt $t {
			if {1 == [timers_is_in $name [lindex $tt 2]]} {
				lset tt 1 [lindex [lindex $tt 1] 2]
				lappend res $tt
			}
		}
		return $res
	}
	
	proc s_utimers {name} {
		variable utimers
		set t [::utimers]
		set res {}
		foreach tt $t {
			if {1 == [utimers_is_in $name [lindex $tt 2]]} {
				lset tt 1 [lindex [lindex $tt 1] 2]
				lappend res $tt
			}
		}
		return $res
	}

}
