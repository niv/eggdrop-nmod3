proc constructor {} {
  register_global ac:isAuthed 1
  register_global ac:getQAuth 1
	if {"" == [info commands getchanlogin]} {
		error "getchanlogin patch not present or not registered with nmod"
	}
}

proc ac:isAuthed {n h} { ;#checks if given nick/handle combination is valid & authed to Q with the account set
	if {[getchanlogin $n] == $h} {
		return 1
	} else {
		return 0
	}
}

proc ac:getQAuth {h} { ;#gets qauth from this handle
	return $h
}
