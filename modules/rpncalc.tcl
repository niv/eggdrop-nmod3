# package require math::bignum

# this is one helluva bad code featuring upvar yours truly

depend_on eggdropcore
depend_on stringtools
depend_on mathtools

set stack(-) [list]

proc constructor {} {
	bind pub - !c    pubcalc
	bind pub - !calc pubcalc
#	bind pub - "."   pubcalc
}

proc help {t {item ""}} {
	switch -- $item {
	"" {
		putmsg $t "A compatible RPN calculator, HP48-style"
		putmsg $t "Arithmetic: + - / * % abs sin sinh asin cos cosh acos ceil tan tanh atan atan2"
		putmsg $t "Arithmetic: & ^ | << >> int double round pow sqrt exp floor log log10 rand"
		#putmsg $t "Number conversion: hex dec oct bin"
		putmsg $t "Constants: pi e c"
		putmsg $t "Helpers: ps: print the current stack; rs: rotate the stack; cs: clear the stack"
		putmsg $t "Helpers: ss: remember stack for next calculation"
		putmsg $t "Helpers: x: output additional number formats (on by def); v: verbose output"
		putmsg $t "Allowed input methods: dec: 42, hex: 0x2a, oct: 052, char: ?*"
		#putmsg $t "For operator help use 'help <operation>'"
	}
	}
}

proc v {msg} {
	upvar t t
	upvar opt opt
	if {-1 != [lsearch $opt "v"]} {
		putmsg $t $msg
	}
}

proc err {msg} {
	upvar t t
	upvar stack stack
	set trace [join $stack ", "]
	putmsg $t "$msg - Stack: \[${trace}\]"
	return 1
}

proc get_stack {id} {
	global stack
	if {![info exists stack($id)]} {
		set stack($id) [list]
	}
	return $stack($id)
}

proc put_stack {s id} {
	global stack
	set stack($id) $s
}

proc cleanup_stack {} {
	global stack
	foreach n [array names stack] {
		if {[llength $stack($n)] == 0} {
			array unset stack $n
		}
	}
}

proc getstackstr {} {
	upvar stack stack
	upvar opt opt
	set r "\["
	foreach i $stack {
		append r $i
		if {[regexp {^\d+$} $i]} {
			append r "=0x"
			append r [format "%x" $i]
		}
		append r ", "
	}
	if {[llength $stack] > 0} {
		set r [string range $r 0 end-2]
	}
	append r "\]"
	return $r
}

proc pubcalc {n u h t r} {
	set args [split $r " "]
	
	set max_stack 30
	set stack [get_stack $t]
	
	foreach nn $stack {
		putlog "inserting $nn into $args at 0"
		set args [linsert $args 0 $nn]
	}
	putlog "args = $args"
	
	set stackprinter 0
	set opt [list "x"]
	
	if {[llength $stack] > 0} {
		v "Warning: Stack is not empty."
	}
	
	set evalRes [catch {
	
	for {set i 0} {$i < [llength $args]} {incr i}  {
		
		
		set o [string tolower [string trim [lindex $args $i]]]

		
		if {[regexp {^(-)?(0x[a-zA-Z0-9]+)$} $o {} sgn hx]} {
			if {[llength $stack] >= $max_stack} {
				return [err "Stack full (max of $max_stack), cannot push: $o"]
			}
			scan $hx "%x" hex
			if {$sgn == "-"} {
				set hex [expr -1 * $hex]
			}
			v "Pushing $o as hex: $hex"
			lappend stack $hex
			continue
		}

		if {[regexp {^-?0[0-9]+[lL]?$} $o]} {
			if {[llength $stack] >= $max_stack} {
				return [err "Stack full (max of $max_stack), cannot push: $o"]
			}
			scan $o "%o" oct
			v "Pushing $o as oct: $oct"
			lappend stack $oct
			continue
		}
		
		if {[regexp {^\?(.)$} $o {} c]} {
			if {[llength $stack] >= $max_stack} {
				return [err "Stack full (max of $max_stack), cannot push: $o"]
			}
			scan $c "%c" cc
			v "Pushing $o as char: $cc"
			lappend stack $cc
			continue
		}

		if {[regexp {^-?\d+$} $o]} { ;# its a int!
			if {[llength $stack] >= $max_stack} {
				return [err "Stack full (max of $max_stack), cannot push: $o"]
			}
			v "Pushing $o as int: [expr int($o)]"
			lappend stack [expr int($o)]
			continue
		}
		
		if {[regexp {^-?\d+\.\d+$} $o]} { ;# its a double!
			if {[llength $stack] >= $max_stack} {
				return [err "Stack full (max of $max_stack), cannot push: $o"]
			}
			v "Pushing $o as fp: [expr double($o)]"
			lappend stack [expr double($o)]
			continue
			
		}

		# shorthands
		if {$o == "**"} { set o "pow" }
		if {$o == "div"} { set o "/" }
		if {$o == "mod"} { set o "%" }
	
		switch -- $o {
			"h" -
			"help" { help $t; return }
			
			"ss" -
			"v" -
			"x" { 
				if {-1 == [set sindx [lsearch $opt $o]]} {
					lappend opt $o
				} {
					set opt [lreplace $opt $sindx $sindx]
				}
			}
			
			"pi" {
				v "Pushing PI"
				lappend stack [expr 3.14159265359]
			}
			"e" {
				v "Pushing e"
				lappend stack [expr 2.71828182845]
			}
			"c" {
				v "Pushing c"
				lappend stack [expr 299792458]
			}

			"+" -
			"-" - 
			"*" {
				if {[llength $stack] < 2} {
					return [err "Stack too small to perform operation: ${o}"]
				}
				set op2 [lindex $stack end]
				set op1 [lindex $stack end-1] 
				v " $op1 $op2 $o"
				set stack [lrange $stack 0 end-2]
				lappend stack [expr $op1 $o $op2]
			}
				
			"&" -
			"^" -
			"|" -
			"<<" -
			">>" {
				if {[llength $stack] < 2} {
					return [err "Stack too small to perform operation: ${o}"]
				}
				set op2 [lindex $stack end]
				set op1 [lindex $stack end-1]

				v "Checking for integer on $op2 $op1 $o"
				
				if {![string is integer $op2] || ![string is integer $op1]} {
					return [err "Cannot perform $o on non-integer values."]
				}
				
				v " $op1 $op2 $o"
				
				set stack [lrange $stack 0 end-2]
				
				lappend stack [expr $op1 $o $op2]
			}


			"%" -
			"/" {
				if {[llength $stack] < 2} {
					return [err "Stack too small to perform operation: ${o}"]
				}
				set op2 [lindex $stack end]
				set op1 [lindex $stack end-1]
				set stack [lrange $stack 0 end-2]
				
				if {$op2 == 0} {
					return [err "Division through zero."]
				}
				v " $op1 $op2 $o"
				lappend stack [expr $op1 $o $op2]
	
			}
			
			"rand" {
				v " $o"
				lappend stack [expr ${o}()]
			}
	
			"abs" -
			"sin" -
			"sinh" -
			"asin" -
			"cos" -
			"cosh" -
			"acos" -
			"tan" -
			"tanh" -
			"atan" -
			"ceil" -
			"double" -
			"exp" -
			"floor" -
			"int" -
			"log" -
			"log10" -
			"round" -
			"sqrt" {
				if {[llength $stack] < 1} {
					return [err "Stack too small to perform operation: ${o}"]
				}
				set op1 [lindex $stack end]
				set stack [lrange $stack 0 end-1]
				v " $o"
				lappend stack [expr ${o}($op1)]
			}
			
			"pow" -
			"atan2" {
				if {[llength $stack] < 2} {
					return [err "Stack too small to perform operation: ${o}"]
				}
				set op2 [lindex $stack end]
				set op1 [lindex $stack end-1]
				set stack [lrange $stack 0 end-2]
				v " $op1 $op2 $o" 
				lappend stack [expr pow($op1,$op2)]
	
			}
			
			"ps" {
				incr stackprinter
				set trace [join $stack ", "]
				putmsg $t "ps(${stackprinter}) = \[${trace}\]"
			}
			
			"rs" {
				set stackx [list]
				for {set l [expr [llength $stack]-1]} {$l >= 0} {incr l -1} {
					lappend stackx [lindex $stack $l]
				}
				v "Rotated stack."
				set stack $stackx
			}
			"cs" {
				v "Stack cleared."
				set stack [list]
			}
			
			default {
				return [err "Unknown identifier encountered: ${o}"]
			}
		}
	}
	
	} experr]
	
	if {$evalRes != 0} {
		err "Error: ${experr}"
		return
	}

	
	set stackx [list]
	for {set i [expr [llength $stack]-1]} {$i >= 0} {incr i -1} {
		lappend stackx [lindex $stack $i]
	}
	set stack $stackx

	if {-1 != [lsearch $opt "ss"]} {
		v "Saving stack."
		lappend stack "ss"
		put_stack $stack $t
	} {	
		put_stack {} $t
	}
	
	
	putmsg $t [getstackstr]	
	cleanup_stack
	return
}

