# phpbb stuff
# todo:
# * anonymous postings
# * persistency
# * dcc config interface
depend_on eggdropcore
depend_on mysql 20050328140000
# depend_on yield 20050327210128


proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050329215900" }
		{ "description" "phpbb channel ticker" }
	}
}

proc constructor {} {
	bind dcc n phpbb dcc
	bind time - * time
	global c s con cache_forum cache_user cache_topic
	# set c(identifier) {
	#  {host port user pass db tableprefix}
	#  {chkcycle reportusers reportthreads reportposts}
	#  { {forum ids to report} {forum ids not to report} }
	#  {notify these targets}
	# }
	set con(regentag) 0
	# now set in init_cache
	# set s(regentag) [list [unixtime] 0 0 0 ] ;# lastchecktime highestuid highestthreadid highestpostid
	
	foreach e [array names c] {
		putlog "Initialising cache for $e"
		init_cache $e
	}
}

proc destructor {} {
	variable con
	log "closing db connections" d
	foreach c [array names con] {
		if {$con($c) != 0} {
			set r [catch {mysqlclose $con($c)} e]
		}
	}
	save_settings
	return
}

# Connects the given handle
proc get_con {id} {
	variable c
	variable con
	if {![info exists con($id)] || $con($id) == 0 || [mysqlstate $con($id)] < 3} {
		# make new
		set n [lindex $c($id) 0]
		set res [catch {mysqlconnect -compress true -host [lindex $n 0] -port [lindex $n 1] -user [lindex $n 2] -password [lindex $n 3] -db [lindex $n 4]} cid]
		if {$res != 0} {
			error "Failed connecting SQL to handle $id: $cid"
		} {
			set con($id) $cid
			return $con($id)
		}
	} {
		return $con($id)
	}
}

# Returns the prefix for given handle
proc get_pfx {id} {
	variable c
	return [mysqlescape [lindex [lindex $c($id) 0] 5]]
}

# Returns the username for the given id
proc get_user_by_id {handle id} {
	global cache_user
	foreach l $cache_user($handle) {
		if {[lindex $l 0] == $id} {
			return [lindex $l 1]
		}
	}
	return ""
}

# Returns the forumname for the given id
proc get_forum_by_id {handle id} {
	global cache_user
	foreach l $cache_forum($handle) {
		if {[lindex $l 0] == $id} {
			return [lindex $l 1]
		}
	}
	return ""
}


proc init_cache {handle {cat ""}} {
	global cache_forum cache_user cache_topic s
	set co [get_con $handle]
	# 1) get all forum names with their id
	# 2) get all users with their id
	set r [catch {mysqlsel $co "SELECT `forum_id`,`forum_name` FROM `[get_pfx $handle]_forums`;" -list} forums]
	if {$r} {
		error "Error building forum cache: $forums"
	}
	set cache_forum($handle) $forums

	set r [catch {mysqlsel $co "SELECT `user_id`,`username` FROM `[get_pfx $handle]_users` ORDER BY `user_id` ASC;" -list} users]
	if {$r} {
		error "Error building user cache: $users"
	}
	set cache_user($handle) $users

	set r [catch {mysqlsel $co "SELECT `topic_id`,`forum_id`,`topic_title`,`topic_poster` FROM `[get_pfx $handle]_topics`;" -list} topics]
	if {$r} {
		error "Error building topic cache: $topics"
	}
	set cache_topic($handle) $topics
	
	set r [catch {mysqlsel $co "SELECT `post_id` FROM `[get_pfx $handle]_posts` ORDER BY `post_id` DESC LIMIT 1;" -flatlist} highestpost]
	if {$r} {
		error "Error getting last post: $highestpost"
	}
	set highestpost [lindex $highestpost 0]
	
	# for simplicity reasons, we set the state information here, too
	set s($handle) [list [unixtime] [lindex [lindex $users end] 0] [lindex [lindex $topics end] 0] $highestpost ]
	return
}


# Returns all latest since the last update
proc get_all_latest {handle} {
	global s
	set lasts [lrange $s($handle) 1 end]
	set lastuserid [lindex $lasts 0]
	# 1) check for users
	
	set r [catch {mysqlsel "SELECT `user_id`,`username` FROM `[get_pfx $handle]_users` WHERE `id` > '$lastuserid' ORDER BY `user_id` DESC;" -list} users]
	if {$r} {
		error "SQL: $users"
	}
	set lastusers $users

	set r [catch {mysqlsel "SELECT `topic_id`,`forum_id`,`topic_title`,`topic_poster` FROM `[get_pfx $handle]_topics` WHERE `id` > '$lastuserid' ORDER BY `user_id` DESC;" -list} topics]
	if {$r} {
		error "SQL: $topics"
	}
	for {set i 0} {$i < [llength $topics]} {incr i} { ;# retrieve the username that made the post
		set t [lindex $topics $i]
		if {[lindex $t 3] == -1} { ;#anonymous!
			set r [catch {mysqlsel "SELECT `post_username` FROM `[get_pfx $handle]_posts` WHERE `topic_id`='[lindex $t 0]' ORDER BY `post_id` ASC LIMIT 1;" -flatlist} username]
			if {$r} { error "SQL: $usernamE" }
			set username [lindex $username 0]
		} {
			set username [get_user_by_id $handle [lindex $t 3]]
		}
		lset topics [list $i 4] $username
	}
	set lasttopics $topics
	
	
	
	return [list $lastusers $lasttopics {}]
}


proc time {args} {
	variable c
	variable s
	global cache_user cache_topic cache_forum
	
	foreach identifier [array names c] {
		if {[lindex $s($identifier) 0] + [lindex [lindex $c($identifier) 1] 0] <= [unixtime]} {
			continue
		}
		lset s($identifier) 0 [unixtime]
		
		set r [catch {get_all_latest $identifier} lids]
		if {$r} {
			log $lids
			continue
		}
		
		set lastusers  [lindex $lids 0] ;# {user_id, username}
		set lasttopics [lindex $lids 1] ;# {topic_id, forum_id, topic_title, topic_poster_id, topic_poster_name}
		set lastposts  [lindex $lids 2] ;# {}
		
		# Is there a new user?
		foreach user $lastusers {
			log "new user '$user', notifying everyone: $notify"
			foreach e $notify { putmsg $e "\[User\] id: [lindex $user 0], name: '[lindex $user 1]'" }
			lappend $cache_user($identifier) $user
		}
		lset s($identifier) 1 [lindex [lindex $lastusers 0] 0]
		putlog "Newest user-id: [lindex $s($identifier) 0]"
		
		foreach topic $lasttopics {
			log "new topic '$topic', notifying everyone: $notify"
			set forum [get_forum_by_id $identifier [lindex $topic 1]]
			set user  [lindex $topic 4]
			set msg "\[Thread: $forum\] '[lindex $topic 2]', by $user"
			if {[lindex $topic 3] == -1} { append msg " (Anonymous)" }
			foreach e $notify { putmsg $e $msg }
			lappend $cache_topic($identifier) $topic
		}
		
		lset s($identifier) 2 [lindex [lindex $lasttopics 0] 0]
		putlog "newest topic-id: [lindex [lindex $lasttopics 0] 0]"
	}
}

proc load_settings {} {
	variable c
	log "loading settings" d
	set fn "[cfg_path]phpbb.settings"
	if {!([file exists $fn] && [file readable $fn])} { return }
	array unset c
	set f [open $fn "r"]
	while {[set s [gets $fn]]} {
		if {![regexp {^([a-z]+): (.+)$} $s {} id ls]} {
			error "invalid field: $s"
		}
		set c($id) $ls
	}
	close $f
	return
}


proc save_settings {} {
	variable s; variable c
	log "saving settings" d
	set fn "[cfg_path]phpbb.settings"
	set f [open $fn "w"]
	foreach e [array names c] {
		puts $f [format "%s: %s" $e $c($e)]
	}
	close $f
	return
}


##########
# User interface below

proc dcc {h i t} {
	set a [split $t]
	set c [lindex $a 0]
	
	switch -- $c {
	
	
		default {
			putidx $i "phpbb-notifier for channels"
			putidx $i " .phpbb list"
			putidx $i " .phpbb show <id>"
			putidx $i " .phpbb add <id> \[key-value-pairs\]"
			putidx $i " .phpbb del <id>"
			putidx $i " .phpbb set <id> <key> <value>"
			return 0
		}
	}
}

