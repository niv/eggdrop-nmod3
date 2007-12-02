#nmod, interp version
# $Id: nmod3.tcl 2 2006-11-17 14:09:33Z elven $
# Head at $HeadURL: svn://swordcoast.net/tcl/trunk/nmod3/nmod3.tcl $

source "scr/nmod3_slaves.tcl"
source "scr/nmod3_core.tcl"

namespace eval ::nmod3 {
	variable nmod
	set nmod(autoload) {eggdropcore}
	set nmod(version) "20050521.163000"
	set nmod(debuglevel) 1
	set nmod(modpath) "/home/eggheads/eggdrop-common/scr/nmod3/"
	set nmod(modext) ".tcl"
	if {![info exists nmod(autoloaddone)]} { set nmod(autoloaddone) 1 }
	
	set nmod(nonstackables) {pub msg dcc bot fil note}
	set nmod(allbinds) {
		act away bcst bot chat chjn chof chon chpt ctcp
		ctcr dcc disc evnt filt flud join kick link load lost mode msg
		msgm need nick nkch notc note part pub pubm raw rcvd rejn sent
		sign splt time topc tout unld wall
	}
	set nmod(globalvars) {
		botnick botname server serveraddress version numversion
		uptime server-online lastbind isjuped handlen config
	}
	
	if {![info exists loaded]} { variable loaded }
	if {![info exists depends]} { variable depends }
	if {![info exists binds]}  { variable binds }
	if {![info exists globs]}  { variable globs }
	if {![info exists custombinds]}  { variable custombinds }
	if {![info exists timers]}  { variable timers }
	if {![info exists utimers]} { variable utimers }
	if {![info exists udefs]}  { variable udefs }
	
	#uplevel #0 trace add execution set enter ::nmod3::m_setenter
	#uplevel #0 trace add execution set leave ::nmod3::m_setleave
	
	proc fsplit {str {splitby " "}} {
		set res [list]
		set old 0
		set first [string first $splitby $str]
		while {$first != -1} {
			set nextItem [string range $str $old [expr $first - 1]]
			lappend res $nextItem
			set old [expr $first + [string length $splitby]]
			set first [string first $splitby $str [expr $first + [string length $splitby]]]
		}
		lappend res [string range $str [expr $old + 0] end]
		return $res
	}
			
	proc log {msg {mod ""} {lvl n} {sublev 0}} {
		variable nmod
		switch -- $lvl {
		  -1 -
			d -
			debug {
				if {[expr {$nmod(debuglevel) - 1}] < $sublev} { return }
				set lvl "\[DEBG[expr {$sublev==0?"":":${sublev}"}]\]"
			}
			0 -
			n -
			notice { set lvl "" }
			1 - 
			w -
			warn { set lvl "\[WARN\]" }
			2 -
			e -
			error { set lvl "\[ERR \]" }
			3 -
			c - 
			critical { set lvl "\[CRIT\]" }
			default { set lvl "\[$lvl\]" }
		}
		if {$mod != ""} {
			putlog "nmod3${lvl}->${mod}: $msg"
		} {
			putlog "nmod3${lvl}: $msg"
		}
		return
	}
	
	proc load {name} {
		if {![regexp {^[a-z][a-z0-9]+$} $name] || $name == "core"} { error [list -5 $name] }
		
		variable loaded
		variable depends
		variable nmod
		variable globs
		variable binds
		variable timers
		variable utimers
		variable udefs
		variable custombinds
		
		if {[info exists loaded($name)]} {
			error [list -1 "already loaded"]
		}
		log "Loading $name.." {} d
		# Read the file into memory.
		set file "${nmod(modpath)}${name}${nmod(modext)}"
		log "Reading file: $file.." {} d
		
		if {![file exists $file] || ![file readable $file]} { error [list -2 "not found or not readable"] }
		set p [open $file r]; set f [read $p]; close $p
		
		log "Setting up interpreter.." {} d
		set r [catch {interp create -- $name} intp] ;#-safe
		if {$r} {
			log " Failed: $intp" {} e
			kill $name
			error [list 3 "interp create: $intp"]
		}
		# ::safe::interpConfigure $intp -statics false -nested false
		$name eval [list set nmod 3]
		
		log "Setting up variable watcher.." {} d
		
		#$name eval [list
		#	proc nmod_set {k {v ""}} {
		#		putlog "key = $k"
		#		putlog "value = $v"
		#		return [::set $k $v]
		#	}
		#]
		
		log "\$bc watchers active.." {} d
		
		log "Initialising variables.." {} d
		set globs($name) {}
		set binds($name) {}
		set depends($name) {}
		set timers($name) {}
		set utimers($name) {}
		set udefs($name) {}
		set custombinds($name) {}

		log "Setting up aliases.." {} d
		set r [catch {do_aliases $name $intp} e]
		if {$r} {
			log " Failed: $e" {} e
			kill $name
			error [list 3 "do_aliases: $e"]
		}
		
		log "Eval'ing the source into interpreter.." {} d
		set r [catch {$intp eval $f} e]
		if {$r} {
			log " Failed: $e" {} e
			kill $name
			error [list 3 "eval: $e"]
		}
		
		# Note that placing this here is not the obvious solution; nor
		# is it perfect; but it works for now.
		log "Adding registered globals.." {} d
		set bc 0
		foreach mod [array names globs] {
			if {$mod == $name} { continue }
			foreach gl $globs($mod) {
				$name alias $gl "::nmod3::${mod}::${gl}"
				incr bc
			}
		}
		log "$bc globals added.." {} d
		
				
		if {  "" == [$name eval info proc nmod]} {
			log "Information about the module cannot be retrieved, proc absent.." {}
			log " -> Assuming old-style script.." {}
		} {
		
		}
		
		
		if {[$name eval info proc constructor] != ""} {
			log "Eval'ing constructor.." {} d
			set r [catch {$name eval constructor} e]
			if {$r} {
				log " Failed: $e" {} e
				kill $name
				error [list -4 "constructor: $e"]
			}
		} {
			log "Constructor not present.." {} w
		}
		
		set loaded($name) [list [unixtime]]
		
		log "$name loaded successfully."
		return 0
	}

	proc unload {name} {
		if {![regexp {^[a-z][a-z0-9]+$} $name] || $name == "core"} { return [list -5 $name] }
		
		variable nmod
		variable loaded
		variable depends
		variable binds
		variable globs
		variable timers
		variable utimers
		variable custombinds
		
		if {![info exists loaded($name)]} {
			error [list -1 "not loaded"]
		}
		
		log "Unloading $name.." {} d
		
		log "Checking deps.." {} d
		foreach md [array names loaded] {
			set mod [lindex $md 0]
			if {$mod == $name} { continue }
			foreach dep $depends($mod) {
				if {$dep eq $name} {
					error [list 5 "$dep depends on $name, can not unload"]
				}
			}
		}
		log "Passed.." {} d
		
		if {[$name eval info proc destructor] != ""} {
			log "Eval'ing destructor.." {} d
			set r [catch {$name eval destructor} e]
			if {$r} {
				log " Failed: $e" {} w
			}
		} {
			log "Destructor not present." {} w
		}
		
		kill $name
		
		log "$name unloaded successfully."
		return 0
	}
	
	proc kill {name} {
		variable nmod
		variable loaded
		variable depends
		variable binds
		variable globs
		variable timers
		variable utimers
		variable udefs
		variable custombinds
		
		log "Tearing down variable watchers.." {} d
		foreach v $nmod(globalvars) {
			set r [catch {$name eval trace remove variable $v write nmod_var_watcher} e]
			if {$r} {
				log " Failed for $v: $e" {} w
			}
		}
		
		log "Deleting interpreter.." {} d
		set r [catch {interp delete $name} e]
		if {$r} { log " Failed: $e" {} w }
		
		log "Unbinding things.." {} d
		set bc 0
		if {[info exists binds($name)]} {
			foreach {type flags cmd procname} [join $binds($name)] {
				set r [catch {s_unbind $name $type $flags $cmd $procname} e]
				if {$r} { log " Failed for $type/$flags/$cmd/$procname: $e" {} w; continue }
				incr bc
			}
		}
		log "$bc binds removed.." {} d
		
		set bc 0
		if {[info exists globs($name)]} {
			log "Removing globals.." {} d
			foreach glob $globs($name) {
				set r [catch {s_deregister_global $name $glob} e]
				if {$r} { log " Failed: $e" {} w; continue }
				incr bc
			}
		}
		log "$bc globals removed.." {} d
		
		log "Deleting namespace.." {} d
		set r [catch {namespace delete "::nmod3::${name}"} e]
		if {$r} { log " Failed: $e" {} w }
		
		log "Killing timers.." {} d
		set bc 0
		if {[info exists timers($name)]} {
			foreach t $timers($name) {
				set r [catch {killtimer [lindex $t 2]} e]
				if {$r} { log " Failed for [lindex $t 2]: $e" {} w; continue }
				incr bc
			}
		}
		log "$bc timers killed.." {} d
		log "Killing utimers.." {} d
		set bc 0
		if {[info exists utimers($name)]} {		
			foreach t $utimers($name) {
				set r [catch {killutimer [lindex $t 2]} e]
				if {$r} { log " Failed for [lindex $t 2]: $e" {} w; continue }
				incr bc
			}
		}
		log "$bc utimers killed.." {} d
		
		log "Removing custom binds.." {} d
		set bc 0
		if {[info exists custombinds($name)]} {
		
		}
		log "$bc binds removed.." {} d
		
		#log "Removing udefs" {} d
		#if {[info exists udefs($name)]} {
		#	foreach d $udefs($name) {
		#		deludef type xx
		#	}
		#}



		catch {unset loaded($name)}
		catch {unset depends($name)}
		catch {unset binds($name)}
		catch {unset globs($name)}
		catch {unset timers($name)}
		catch {unset utimers($name)}
		catch {unset custombinds($name)}
		return
	}
		

	proc sl_command {name command args} {
		log "$command: \[\"[join $args {", "}]\"\]" $name d 1
		if {[info proc "::nmod3::s_${command}"] != ""} {
			log " -> going to defined proc" $name d 2
			return [eval [concat [list "::nmod3::s_${command}"] $name $args]]
		} {
			return [eval [concat [list $command] $args]]
		}
	}
	
	proc m_setenter {cmd op} {
		variable nmod
		variable varval
		set cmd [split $cmd]
		if {[llength $cmd] < 3} { return } ;#abort if it isnt setting a var
		set varname [lindex $cmd 1]
		if {[lsearch -exact $nmod(globalvars) $varname] != -1} {
			set varval($varname) [uplevel #0 [list set $varname]]
		}
	}
	
	proc m_setleave {cmd code res op} {
		variable loaded
		variable nmod
		variable varval
		set cmd [split $cmd]
		set varname [lindex $cmd 1]
		if { ([lsearch -exact $nmod(globalvars) $varname] != -1) && 
			[info exists varval($varname)] &&
			($varval($varname) != [uplevel #0 [list set $varname]]) } {
				putlog "updating $varname in mods"
				foreach mod [array names loaded] {
					#$mod eval [list set $varname [uplevel #0 [list set $varname]]]
				}
		}
	}
	
	proc sl_var_watcher {name n1 n2 op} {
		log "Variable $n1 was changed to [$name eval set $n1]" $name d
		error "cannot change things"
	}
	
	
	###############
	# master procs
proc strace {} {
        set ret {}
        set r [catch {expr [info level] - 1} l]
        if {$r} { return {""} }
        while {$l > -1} {
                incr l -1
                lappend ret [info level $l]
        }
        return $ret
} 
	
	proc m_handle_bind_error {name procname error} {
		set pn [lindex [split $procname] 0]
		log "nmod3: Error in bind on \"$pn\": $error" $name w
		log " Parameters passed: [join [lrange [split $procname] 1 end]]" $name n
		set t [strace]
		foreach i $t {
			putlog "Trace: $i"
		}
	}
	
	proc m_ontimer {name command} {
		variable timers
		log "timer expired: \[\"[join $command {\", \"}]\"\]" $name d 1
		set n {}
		foreach t $timers($name) {
			if {[lindex $t 1] == $command} { log " -> removed from list." $name d 1; continue }
			lappend n $t
		}
		set timers($name) $n
		set r [catch {$name eval $command} e]
		if {$r} {
			log "Error in timer-script: $e" $name e
			log " Was: $command" $name
		}
	}

	proc m_onutimer {name command} {
		variable utimers
		log "utimer expired: \[\"[join $command {\", \"}]\"\]" $name d 1
		set n {}
		foreach t $utimers($name) {
			if {[lindex $t 1] == $command} { log " -> removed from list." $name d 1; continue }
			lappend n $t
		}
		set utimers($name) $n
		set r [catch {$name eval $command} e]
		if {$r} {
			log "Error in utimer-script: $e" $name e
			log " Was: $command" $name
		}
	}
	
	proc get_loaded {} {
		variable loaded
		return [array names loaded]
	}
	
	##############
	# outsourced things
	proc do_aliases {name intp} {
	
		# nmod-specific
		foreach cmd {
			depend_on register_global deregister_global
			register_bind deregister_bind callbind
		} {
			$intp alias "$cmd" "::nmod3::sl_command" $name $cmd
		}
		
		##### NOT implemented yet, because they need special security wrappers:
		#####
		# setudef renudef deludef binds logfile
		# unames
		#	setpwd getpwd getfiles getdirs dccsend filesend fileresend setdesc getdesc
		#	setowner getowner setlink getlink getfileq getfilesendtime mkdir rmdir
		#	mv cp getflags setflags
		
		# putxferlog putloglev
		# save reload backup getting-users
		# jump die callevent
		# modules loadmodule unloadmodule loadhelp unloadhelp reloadhelp restart rehash
		
		# compressfile uncompressfile iscompressed
		#####
		#####
		foreach cmd {
			::load
			
			log binds bind unbind putidx putlog putcmdlog
		
			timer utimer timers utimers killtimer killutimer
			
			putserv puthelp putquick putkick 
			dumpfile queuesize clearqueue

			countusers validuser finduser userlist passwdok getuser setuser
			chhandle chattr botattr matchattr adduser addbot deluser delhost
			addchanrec delchanrec haschanreg getchaninfo setchaninfo newchanban
			newban newchanexempt newexempt newchaninvite newinvite stick
			unstick stickexempt unstickexempt stickinvite unstickinvite killchanban
			killban killchanexempt killexempt killinvite ischanjuped isban ispermban
			isexempt ispermexempt isinvite isperminvite isbansticky isexemptsticky
			isinvitesticky matchban matchexempt matchinvite banlist exemptlist
			invitelist newignore killignore ignorelist isignore
			
			channel savechannels loadchannels channels channame2dname chandname2name
			isbotnick botisop botishalfop botisvoice botonchan isop ishalfop wasop
			washalfop isvoice onchan nick2hand hand2nick handonchan ischanban
			ischanexempt ischaninvite chanbans chanexempts chaninvites resetbans
			resetexempts resetinvites resetchan getchanhost getchanjoin onchansplit
			chanlist getchanidle getchanmode pushmode flushmode topic validchan
			isdynamic

			putdcc dccbroadcast dccputchan boot dccsimul hand2idx idx2hand valididx
			getchan setchan console echo strip putbot putallbots killdcc bots botlist
			killdcc islinked dccused dcclist whom getdccidle getdccaway setdccaway
			connect listen traffic dccdumpfile
			
			notes erasenotes listnotes storenote assoc killassoc
			
			maskhost unixtime duration strftime ctime myip rand control sendnote link
			unlink encrypt encpass dnslookup md5
			
			stripcodes
			
			getchanlogin
			
		} {
			if {[string trim $cmd] == ""} { continue }
			$intp alias "$cmd" "::nmod3::sl_command" $name $cmd
		}
	}
}
