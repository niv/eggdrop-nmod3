# 2.2c
#  * Adjusted to the changes quakenet made
# 
# 2.2b
#  * Fixed yet-another-blatant-bug
#    (invalid command name ^). 
#     -- Thanks, Tankred :)
#
# 2.2
#  * Fixed q-enforcebans/unbanall bug
#  * Fixed No-L-Chanflags-listing-pending bug -- thanks to Tankred
#  
#  * ATTENTION:
#     with this release, the chanflag 'paranoid' was
#     removed and replaced with:
#       noserviceprotect
#     rename will be done automagically.
#
# 2.1
#  * Added .qnet auth to force (re)auth to Q
#      which should not be needed anyways - thanks dju`
#  * Fixed bug where parsing got stuck when there were
#      no flags on L
#  * Fixed L check for +v when bot has no +v flag
#  * Fixed bug when channel was set inactive
#  * Fixed qnet:mode continue bug
#
# 2.0
#  * Renamed file to fit into the new collection (gamesnet,
#      etc) which will be available when i've got time to
#      modify it (read: when the cows learn to fly)
#  * dotted some i and such, shiny new layout of .qnet status
#  * proper voice-requesting when bot has +v chanlev now
#  * only requesting stuff when channel is completely synced
#  * fixed qnet:mode error ($chan) on network desync
#  * fixed invite-bug when bot had no L v-flag
#  * fixed that durned L o no op bug!! grr
#  * 2.0 Version, hopefully all bugs purged :)
#
# .. ..
#
# .. much later .. 
#
# .. some internal versions later ..
#
# 1.7c
#  * Fixed usex (should be, at least) - thanks to SneezyD, never
#  * Fixed lost-server-no-auto-reauth-bug - thanks to SneezyD
#  * Added flood-ignore-protection for Q & L
#
# 1.7b
#  * Moved the usex-setting to botconfig-defined-stuff
#  * Added flud-bind to prevent ignoring of Q/L
#
# 1.7a
#  * not updating whoami if authname is 0
#  * +noserviceop +noservicevoice added
#  * added need-voice
#

#thats yet to come, perhaps .. some day .. if ever.
# - Add hidewhoamispam feature, thanks to never - yet to be done
# - dynamic chanlevs of other users
# - seamless integration with my q ac token script - yet to be released


#      �QbyQElvenQ` 
#     QQLQQ    QQQQQ
#   QQQQQ        QQLQQ
#  QQLQQ          QQQQQ
#  QQQLQ          QQQLQ
#  QQQQQ          QQQQQ
#  QQQLQ          QLQQQ
#  QLQQQ          QQQLQ
#   QQQQQ       QQQLQQ
#    `QLQQQ    QQLQQQ
#      `QMMOOOOOHQ�`QQQ
#                      Quakenet Auth

# QNet Auth
# by Elven <elven@elven.de>
# If you find any bugs 
#  actually DO have any critics ;), good or bad,
#  please send me an email or privmsg me on Quakenet (Elven)
#  -- thank you
#
# LEGAL DISCLAIMER:
#  THIS SCRIPT IS UNDER THE GPL LICENCE.
#   For more information see the accompanying gpl.txt or (if missing)
#   http://www.gnu.org/licenses/gpl.txt

# Short description:
#  - keeps your bot authed to Q
#  - tracks his own chanlevs
#  - ops/invites/unbans/etc himself when needed

# -------------------------------------
# For a complete documentation of all features please go to
#  http://projects.elven.de/tcl/q.htm
# -------------------------------------

#
# Make sure Q & L are added as global friends & global ops!
# Its not necessary, but recommended to avoid clashes in general.
# 
# Load the script. If nothing goes wrong, try .qnet status on the
# partyline as global owner.
#

if {[info exists nmod]} {
	depend_on eggdropcore
}

#################
# settings below

set qnet(usedynamic) 2
  #use dynamic authflag retrieval (/msg q|l whoami)
  #set to 2 for strict (clear list before each auth)
  #  (recommended, unless you are using some hack)
  # If you are not using dynamic authes you NEED to set
  # your flags manually:
  # set lflag(#onechan) "o"
  # set qflag(#otherchan) "mno"
  # dont worry about this if you are using 2 here
  
set qnet(usedynchan) 0
  # use dynamic chanlevs
  # buggy - simply do not use it (yet), it just does not
  # work.

set qnet(qservice) "Q@cserve.quakenet.org"
set qnet(lservice) "L@lightweight.quakenet.org"
set qnet(oservice) "O"
  #no change needed on quakenet

set qnet(useoperserv) 0
  #use /MSG O REQUESTOP on channels where no op is?
  #this is NOT functional ATM, this setting has no effect
  #whatsoever
  
set qnet(splittime) 60
  #delay between reqop attempts if there is a split

if {![info exists qnet(user)]} { set qnet(user) "-Username" }
if {![info exists qnet(pass)]} { set qnet(pass) "-Password" }
if {![info exists qnet(usex)]} { set qnet(usex) 0 } ;#set mode +x on connect (authname.users.quakenet.org cloakhost)
  #you need to reconnect to unset this
  
if {![info exists qnet(authmethod)]} { set qnet(authmethod) 1 }
  #set the auth method
  # 0 - use $qnet(user) && $qnet(pass)
  # 1 - retrieve from authfile via $ident (see below)
  #      if you are using a huge botnet running
  #      on the same host, it may be convenient
  #      to use 1 - else use 0!

if {![info exists qnet(authfile)]} { set qnet(authfile) "/home/eggheads/.auth" }
  # This is very useful if you run multiple bots from the same directory
  # with different config files. This way, you dont need to set $qnet(user) etc
  # in each file, just edit your .auth (or eqiv) file. And its neat to
  # backup, too :) Just make VERY sure noone can get their hands on it. (chmod 400)
  # (even through 3rd-party scripts). Its probably a good idea to name it
  # to something else than "~/.auth".
  #
  # To use it, do "set qnet(authmethod) 1" in your bot config file.
  #
  # The file format is as following:
  #  For each running bot 1! line; each line consists of three fields:
  #  <ident>[some space]<username>[some space]<password[enter]
  #  username & password is the Q auth data,
  #   ident identifies your bot. Each bot needs to have a global var
  #   called $ident.

set qnet(chktmr) 600
  #check if we are authed every x seconds
  #do not set this too low
  #works fine the way it is.


#set qnet(hidewhoamispam) 1
  #NOT FUNCTIONAL AT THE MOMENT.
  #blocks all WHOAMI replies from Q/L when requested
  #by the script (does not log & does not spam it to
  #the partyline)

###########################
#code below - read: you do
# not need to edit further
set qnet(version) "2.2b"

if {$qnet(authmethod) == 1} {
  if {![info exists ident] || [array exists ident] || $ident == "" } {
    unset qnet
    error "Load aborted, no or invalid \$ident found. If you are using authmethod = 1 and \$ident is used by some other script, change all 'ident' variable occurences in this one to a new name of your liking."
    return
  }
} {
  if {![info exists qnet(user)] || ![info exists qnet(pass)] || $qnet(user) == "-Username" || ![info exists qnet(usex)]} {
    unset qnet
    error "Load aborted, no or invalid \$qnet(user|pass|usex) found."
    return
  }
}

catch {
  renudef flag paranoid noserviceprotect
} ;#rename the old one, but dont choke if it does not exist
setudef flag noserviceprotect
setudef flag noserviceop
setudef flag noservicevoice

catch { unset lflag(-none) } ;#that was a stupid idea, never mind it
catch { unset qflag(-none) }

bind evnt   "-" "init-server"       qnet:init
bind evnt   "-" "rehash"            qnet:init
bind evnt   "-" "disconnect-server" qnet:init
bind msgm   "-" "*"                 qnet:msgm
bind notc   "-" "*"                 qnet:notc
bind need   "-" "#* *"              qnet:need
bind dcc    "n" "qnet"              qnet:dcc
bind flud   "-" "*"                 qnet:flood
bind time   "-" "*"                 qnet:timechk
bind mode   "-" "#% %"              qnet:mode
bind raw    "-" "396"               qnet:raw396
#bind filt  "-"  "*"                 qnet:filt ;#looks bad

;#yapyap
if {![info exists qnet(authname)]} { set qnet(authname) 0 }
if {![info exists qnet(userid)]} { set qnet(userid) 0 }
if {![info exists qnet(lastauth)]} { set qnet(lastauth) 0 }
if {![info exists qnet(lastupdate)]} { set qnet(lastupdate) 0 }
if {![info exists qnet(authed)]} { set qnet(authed) 0 }
if {![info exists qnet(email)]} { set qnet(email) 0 }
if {![info exists qnet(Llisting)]} { set qnet(Llisting) 0 }
if {![info exists qnet(netsplit)]} { set qnet(netsplit) 0 }
if {![info exists qnet(cloaked)]} { set qnet(cloaked) 0 }

;#start the timer!
utimer $qnet(chktmr) "qnet:chktimer"

###########################
#shinywhite code below here

#proc qnet:filt {idx text} {
#  if {$text == ".status"} {
#    qnet:dcc [idx2hand $idx] $idx status
#  }
#  return $text 
#}

#proc qnet:status {hand idx param} {
#  *dcc:status $hand $idx $param
#  qnet:dcc $hand $idx "status"
#}

proc qnet:flood {n u h t c} {
  if {$n == "Q" || $n == "L"} { return 1 }
  return 0
}

proc qnet:raw396 {f k t} {
  global qnet botnick
  #if {$t!= "$botnick "} { return }
  set qnet(cloaked) 1
}

proc qnet:timechk {min hr day mon yr} {
  foreach chan [channels] {
    if {[botisop $chan] || [botisvoice $chan]} { continue } ;#we have op or voice already
    qnet:need $chan "voice"
  }
  return
}

proc qnet:mode {n u h c m v} {
  if {![isbotnick $v] || [isbotnick $n]} { return }
  switch -exact -- $m {
    "-o" {
      #if {[botisvoice $c]} { return }
      qnet:need $c "op"
    }
    "-v" {
      #if {[botisop $c]} { return }
      qnet:need $c "voice"
    }
  }
  return
}

proc qnet:chktimer {} {
  global qnet
  if {![string match "*qnet:chktimer*" [utimers]]} { utimer $qnet(chktmr) "qnet:chktimer" }  
  if {!$qnet(authed)} { qnet:auth ; return }
  if {$qnet(authname)==0} { qnet:update }
  return
}

proc qnet:init {t} {
  global qnet botnick
  if {$t == "init-server"} {
    if {$qnet(usex)==1} { putquick "MODE $botnick +x" -next; putlog "Engineering, engage the cloaking device. (+x)" }
    qnet:auth
  }
  if {$t == "disconnect-server"} {
    set qnet(authed) 0
    set qnet(cloaked) 0
    putlog "We got disconnected, clearing authentication flag."
  }
  if {$t == "rehash"} {
    if {!$qnet(cloaked) && $qnet(usex)==1} { putserv "MODE $botnick +x" -next; putlog "Engineering, engage the cloaking device. (+x)" }
  }
  return
}

proc qnet:onuserhost {f k t} {
  global botnick
  if {[regexp "$botnick :Q*=+TheQBot@CServe.quakenet.org" $t]} {
    #todo!
  }
}

proc qnet:auth {} {
  global ident qnet
  if {$qnet(authed)} { return 0 }
  if {[expr $qnet(lastauth) + $qnet(chktmr)] > [unixtime]} { return 0 }
  if {$qnet(authmethod) == 0} {
    set auth [list $qnet(user) $qnet(pass)]
  } {
    set auth [qnet:retrauth $ident]
  }
  if {$auth == 0} { putlog "Could not retrieve auth information, aborting auth." ; return }
  putquick "PRIVMSG $qnet(qservice) :AUTH [join $auth]" -next
  set qnet(lastauth) [unixtime]
  return 1
}

proc qnet:retrauth {u} {
  global qnet
  if {$qnet(authmethod)==0} {
    return [list $qnet(user) $qnet(pass)] ;#we should never be here since auth checks this itself, but well ..
  } {
    set f [open $qnet(authfile) "r"]
    while {![eof $f]} {
      set res [gets $f]
      if {[regexp -- {^(\S+)\s+(\S+)\s+(\S+)$} $res x0 user auth pass]} {
        if {[string tolower $user] == [string tolower $u]} { return [list $auth $pass] }
      }
    }
    close $f
  }
  return 0
}

proc qnet:update {} {
  global qnet
  if {!$qnet(authed)} { return 0 }
  catch { unset ::lflag }
  catch { unset ::qflag }
  putquick "PRIVMSG Q :whoami"
  putquick "PRIVMSG L :whoami"
  return 1
}

proc qnet:notc {n u h t {d ""}} {
  global botnick; if {$d != $::botnick} { return 0 }  
  if {[string trim $t]==""} { return }
  global qnet qflag lflag qnet_dl qnet_dq
  if {$u == "TheQBot@CServe.quakenet.org"} {
    if {[string trim $t] == "AUTH'd successfully."} {
      set qnet(authed) 1
      putlog "Got authentication response, we are authed \\o/`."
      if {$qnet(usedynamic)} {
        if {$qnet(usedynamic)==2} {
          catch { unset qflag }
          catch { unset lflag }
          set qnet(authname) 0
        }
        qnet:update
      }
    }
    if {[string trim $t] == "If you are known by Q type:  \"/msg Q@CServe.quakenet.org AUTH nickname password\""} {
      set qnet(authed) 0
    }
    if {[string trim $t] == "Username or password incorrect, or you are already authed."} {
      putlog "Either you tried to auth again, or your USERNAME/PASSWORD IS INCORRECT!"
    }
    
    if {[regexp {^You have authed as userid: (\d+) nick: (\S+)$} $t xx x0 x1]} {
      set qnet(userid) $x0
      set qnet(authname) $x1
    }
    
    if {[regexp {^You have NOT authed$} $t]} {
      qnet:auth
    }
    
    if {[regexp {^E-mail: (.+)$} $t xx x0]} {
      set qnet(email) $x0
    }
    
    if {[regexp {^Access level \+(\S+) on channel (#\S+)\.$} $t xx x0 x1]} {
      if {!$qnet(usedynamic)} { return }
      set x1 [string tolower $x1]
      set qflag($x1) $x0
    }
    
    if {!$qnet(usedynchan)} { return }
    if {[regexp {^Known users on (#\S+) are:$} $t x0 ch]} {
      set qnet(qchanlist) [string tolower $ch]
      set qnet_dq($qnet(qchanlist)) [list]
    }
    if {[regexp {^\s+(\S+)\s+Modes:\s+\+(\S+)$} $t x0 usr mod]} {
      lappend qnet_dq($qnet(qchanlist)) [list $usr $mod]
    }
    if {[regexp {^End of list\.$} $t]} {
      set qnet(qchanlist) 0
    }
    
    return
  }
  
  if {$u == "TheLBot@lightweight.quakenet.org"} {
    if {[string trim $t] == "You are not authed.  Please auth with Q before sending me commands."} {
      set qnet(authed) 0
      qnet:auth
    }
    if {[regexp {^Sorry, you need the \+o flag on (\S+) to get ops\.$} $t xx x0]} {
      #we dont have op there
      set x0 [string tolower $x0]
      putlog "Error in config: We don't have op-flag on $x0, even if our config says so. Unsetting."
      unset lflag($x0)
    }
    if {[regexp {^Sorry, you need the \+v flag on (\S+) to use voice\.$} $t xx x0]} {
      set x0 [string tolower $x0]
      putlog "Error in config: We don't have voice-flag on $x0, even if our config says so. Unsetting."
      unset lflag($x0)
    }
    
    if {[regexp {^You are authed as (\S+)$} $t]} {
      if {!$qnet(usedynamic)} { return }
      set qnet(Llisting) 1
    }
    if {[regexp {^End of list\.$} $t]} {
      if {!$qnet(usedynamic)} { return }
      set qnet(Llisting) 0
    }
    if {[regexp {^([^ ]+) is not known on any channels\.$} $t crap ani]} {
      if {$ani != $qnet(authname)} { return }
      if {!$qnet(usedynamic)} { return }
      set qnet(Llisting) 0
    }
    
    if {[regexp {^(#\S+)\s+(\S+)$} $t xx x0 x1]} {
      if {!$qnet(usedynamic)} { return }
      if {!$qnet(Llisting)} { return }
      set x0 [string tolower $x0]
      set lflag($x0) $x1
    }
    
    if {!$qnet(usedynchan)} { return }
    global qnet_dl
    #dynamic chanlev
    if {[regexp {^Users for channel (#\S+)$} $t x0 chn]} {
      set qnet(lchanlist) [string tolower $chn]
      set qnet_dl($qnet(lchanlist)) [list]
    }
    
    if {[regexp {^(\S+)\s+(\S+)$} $t x0 au fl]} {
      if {$qnet(lchanlist)==0} { qnet:log "Error?!: got chaninfo $au $fl, but no chan set" 1; return }
      lappend qnet_dl($qnet(lchanlist)) [list $au $fl]
    }
    
    if {[regexp {^End of chanlev for (#\S+)\.$} $t x0 chn]} {
      set qnet(lchanlist) 0
    }
    
    return
  }
  return
}

proc qnet:msgm {n u h t} {
  global qnet
  if {!$qnet(useoperserv)} { return }
  if {$n == "O"} {
    if {$t == "For obvious reasons, you cannot request ops during a netsplit."} {
      set qnet(netsplit) [unixtime]
    }
  }
}

proc qnet:hasqflag {c f} {
  global qflag ; set i 0 ; set c [string tolower $c]
  if {![info exists qflag($c)]} { return 0 }
  while {$i < [string length $f]} {
    if {[string match "*[string index $f $i]*" $qflag($c)]} { return 1 }
    incr i
  }
  return 0
}

proc qnet:haslflag {c f} {
  global lflag ; set i 0 ; set c [string tolower $c]
  if {![info exists lflag($c)]} { return 0 }
  while {$i < [string length $f]} {
    if {[string match "*[string index $f $i]*" $lflag($c)]} { return 1 }
    incr i
  }
  return 0
}

proc qnet:putmsg {c t x} {
  global qnet
  switch -exact -- $x {
    1 { putquick "PRIVMSG $qnet(qservice) :$t $c" -next }
    2 { putquick "PRIVMSG $qnet(lservice) :$t $c" -next }
  }
}

proc qnet:matchattr {chan flags {auth ""}} {
  global qnet lflag qflag ; set c [string tolower $chan]
  #returns:
  # 0 - no flag
  # 1 - flag on Q
  # 2 - flag on L
  if {![info exists lflag($chan] && [info exists qflag($chan)]} {
    #q channel
    set i 0 ; while {$i < [string length $flags]} {
      if {[string matches "*[string index $flags $i]*" $qflag($chan)]} { return 1 }
    }
  } elseif {[info exists lflag($chan)] && ![info exists qflag($chan)]} {
    set i 0 ; while {$i < [string length $flags]} {
      if {[string matches "*[string index $flags $i]*" $lflag($chan)]} { return 2 }
    }
  } {
    return 0
  }  
}

proc qnet:need {c t} {
  global qnet botnick
  if {![validchan $c] || [channel get $c inactive]} { return }
  set c [string tolower $c]
  if {!$qnet(authed)} {
    #For some reason we aren't authed, trying to auth.
    qnet:auth ; return
  }
  if {$qnet(authname)==0} {
    qnet:update; return
  }
  
  set serv 0
  set isqop [qnet:hasqflag $c "mno"]
  set isqmaster [qnet:hasqflag $c "mn"]
  set isqvc [qnet:hasqflag $c "mnv"]
  set islop [qnet:haslflag $c "mno"]
  set islmaster [qnet:haslflag $c "mn"]
  set islvc [qnet:haslflag $c "mnv"]
  
  if {$islmaster || $islop || $islvc} { ;#we prefer L .. its nicer to us, it doesnt ban us on sight!
    set serv 2
    set isop $islop
    set isvc $islvc
    set ismaster $islmaster
  } elseif {$isqmaster || $isqop || $isqvc} {
    set serv 1
    set isop $isqop
    set isvc $isqvc
    set ismaster $isqmaster
  } else {
    return ;#TODO: fix me sometime later. doesnt work as of now, dont bother understanding it
    if {$t != "op"} { return }
    if {!$qnet(useoperserv)} { return }
    foreach x [chanlist $c] {
      if {[isop $x $c]} { return }
    }
    if {$qnet(netsplit)!=0} {
      if {[expr [unixtime] - $qnet(netsplit)] > $qnet(splittime)} { return }
      set qnet(netsplit) 0
    }
    putmsg $qnet(oservice) "requestop $c $botnick"
    return
  };#end of dont-bother-mode
  
  if {$serv == 0} { return }
  
  switch -exact -- $t {
    "op" {
      if {[channel get $c noserviceop]} { return }
      if {$isop} { qnet:putmsg $c "op" $serv }
    }
    "voice" {
      if {[channel get $c noservicevoice]} { return }
      if {$isvc} { qnet:putmsg $c "voice" $serv }
    }
    
    "unban" {
      if {[channel get $c noserviceprotect]} {
        if {$serv == 1} { ;#Q
          if {!$isop} { return } ;#we are banned and cannot remove the ban. eg, q would force us out again
          qnet:putmsg $c "unbanall" $serv
        } { ;#L
          if {$isvc} { qnet:putmsg $c "invite" $serv } ;#we invite ourselves, eggdrop takes care of the rest
        }
      } else {
        if {$serv == 1} {
          if {!$ismaster || !$isop} { ;#we cant do anything .. see above
            return
          }
          ;#lets rock!
          qnet:putmsg $c "deopall" $serv
          qnet:putmsg $c "unbanall" $serv
          qnet:putmsg $c "clearchan" $serv
        } else {
          if {$ismaster} {
            qnet:putmsg $c "recover" $serv
          } elseif {$isop} {
            qnet:putmsg $c "deopall" $serv
            qnet:putmsg $c "unbanall" $serv
            qnet:putmsg $c "clearchan" $serv
          } elseif {$isvc} { ;#invite ourselves, if there is nothing else to do
            qnet:putmsg $c "invite" $serv
          } ;#else: we cant do anything, sorry sir!
        }
      }
    } 
    
    "limit" {
      if {[channel get $c noserviceprotect]} {
        if {$serv == 1} { ;#Q
          if {$isvc} { qnet:putmsg $c "invite" $serv }
        } { ;#L
          if {$isvc} { qnet:putmsg $c "invite" $serv }
        }
      } else {
        if {$serv == 1} {
          if {!$ismaster || !$isop} { ;#we cant do anything but invite ourselves
            qnet:pugmsg $c "invite" $serv
            return
          }
          qnet:putmsg $c "deopall" $serv
          qnet:putmsg $c "unbanall" $serv
          qnet:putmsg $c "clearchan" $serv
        } else {
          if {$ismaster} {
            qnet:putmsg $c "recover" $serv
          } elseif {$isop} {
            qnet:putmsg $c "deopall" $serv
            qnet:putmsg $c "unbanall" $serv
            qnet:putmsg $c "clearchan" $serv
          } elseif {$isvc} { ;#invite ourselves, if there is nothing else to do
            qnet:putmsg $c "invite" $serv
          } ;#else: we cant do anything, sorry sir!
        }
      }
    }

    "invite" {
      if {$isop || $isvc} {
        qnet:putmsg $c "invite" $serv
      }
    }

    "key" {
      if {$isop || $isvc} {
        qnet:putmsg $c "invite" $serv
      }
    }
    
    default {
      putlog "qnet:need called with unknown parameter $t."
    }
  }
  return
}







######################
# interface stuff


proc qnet:dcc {h i t} {
  set lst [split $t]
  set cmd [lindex $lst 0]
  set arg [join [lrange $lst 1 end]]
  global qnet lflag qflag
  switch -exact -- $cmd {
    "info" {
      putidx $i "\002.qnet info\002 is deprecated. Use '.qnet status'"
      putidx $i "  This change ensures 'visual compatibility' with other scripts"
      putidx $i "  and the default eggdrop functionality."
      return 0
    }
    "status" {
      if {$qnet(authed)} {
        putidx $i "Quakenet Auth: v${qnet(version)}"
        if {$qnet(authname) == 0} {
          putidx $i " Error: No auth information available. Please use .qnet update to fix this."
          putidx $i "  This should not happen normally, and if, only after (re)connect."
          putidx $i "  If this problem persists, contact me please. It is most likely a bug."
          return 1
        }
        if {$qnet(Llisting) == 1} {
          putidx $i " Im currently at the task of updating this list. Try again in a few seconds."
          return 1
        }
        putidx $i " I am authed as $qnet(authname) with userid $qnet(userid)."
        putidx $i "  The email set is: $qnet(email)"
        if {$qnet(usedynamic)} { putidx $i " I am using dynamic flag retrieval." } { putidx $i " I am not using dynamic flag retrieval." }
        putidx $i "  My st auth was [duration [expr [unixtime]-$qnet(lastauth)]] ago."
        putidx $i "  Channel listing:"
        putidx $i "   Q"
        if {[array size qflag]==0} {
            putidx $i "    - No flags."
        } {
          foreach x [array names qflag] {
            set fstr [format "%-30s %6s" "$x" "$qflag($x)"]
            putidx $i "    $fstr"
          }
        }
        putidx $i "   L"
        if {[array size lflag]==0} {
          putidx $i "    - No flags."
        } {
          foreach x [array names lflag] {
            set fstr [format "%-30s %6s" "$x" "$lflag($x)"]
            putidx $i "    $fstr"
          }
        }
        putidx $i "  End of listing."
      } {
        putidx $i " I am not authed currently."
      }
      putidx $i " End of info."
      return 1
    }
    
    "update" {
      if {!$qnet(usedynamic)} {
        putidx $i "Dynamic flag retrieval is disabled."
        return 1
      }
      putidx $i "Sending whoami to Q & L."
      if {![qnet:update]} {
        putidx $i "Update failed, i am not authed - authing."
      }
      return 1
    }
    "auth" {
      putidx $i "Authing .."
      if {$arg == "force"} {
        set qnet(authed) 0
        putidx $i "  Forcing auth."
      } {
        putidx $i "  Use \002.qnet auth force\002 to force auth."
      }
      qnet:auth
    }
    "about" {
      putidx $i "Quakenet Auth: v${qnet(version)}"
      putidx $i " Go to http://projects.elven.de/tcl/q.htm for instructions & updates."
      return 1
    }
    default {
      putidx $i "Syntax: .qnet <status|update|auth|about> - Use update only when necessary (chanflag added/removed)!"
      return 0
    }
  }
}

putlog "QNet Auth v${qnet(version)} by Elven <elven@elven.de> loaded."
