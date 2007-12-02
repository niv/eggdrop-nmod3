# HTTP encapsulation
# for nmod
# Copyleft 2004 by Elven
# GNU/GPL

# API provided:
#   http:get $url [$timeout]
#   http:head $url [$timeout]
#   http:post $url $postdata [$timeout]
# And the same async:
#   http:aget $callback $id $url ..
#    ff ..
# Callback:  proc callback {id token}
#   $id is the number you supplied
#   $token is the NAME of an array
#    where your data is
#

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "20050327210128" }
		{ "description" "http abstraction" }
	}
}

proc constructor {} {
	package require http
	# package require tls
	load /usr/lib/libtls1.50.so
	source /usr/lib/tls1.50/tls.tcl
	::http::register https 443 ::tls::socket
	register_global http_get
	register_global http_head
	register_global http_post
	register_global http_aget
	register_global http_ahead
	register_global http_apost
	return
}

proc destructor {} {
}

set http(agent) "Mozilla"
set http(timeout) 2000

# dlist is [list key val key val]
proc http_urlencode {dlist} {
  return [::http::formatQuery $dlist]
}

proc http_get {query {timeout 2000}} {
  return [http_request $query get $timeout]
}

proc http_head {query {timeout 2000}} {
  return [http_request $query head $timeout]
}

proc http_post {query {data ""} {timeout 2000}} {
  return [http_request $query post $timeout data]
}

proc http_aget {callback id query {timeout 2000}} {
  return [http_arequest $callback $id $query get $timeout]
}

proc http_ahead {callback id query {timeout 2000}} {
  return [http_arequest $callback $id $query head $timeout]
}

proc http_apost {callback id query {data ""} {timeout 2000}} {
  return [http_arequest $callback $id $query post $timeout data]
}



proc http_request {query type {timeout 2000} {postdata ""}} {
  variable http
  ::http::config -useragent $http(agent)
  set qdata [::http::formatQuery $postdata]
  set r [catch {
    switch -- $type {
      "head" { set token [::http::geturl $query -validate 1 -timeout $timeout] }
      "get" { set token [::http::geturl $query -timeout $timeout] }
      "post" { set token [::http::geturl $query -query $qdata -timeout $timeout] }      
      default { error "Unknown type specified: must be of head, get, post" }
    }
  } err]
  if {$r != 0} {
    error $err
  }
  upvar #0 $token state
  set head $state(meta)
  set body $state(body)
  
  return [list $head $body]
}



proc http_callback {callback id token} {
  namespace eval "::" "$callback $id $token"
  return
}

proc http_arequest {callback id query type {timeout 10000} {postdata ""}} {
  set id [string trim $id]
  if {![string is integer $id]} {
    error "\$id may be an integer, only."
  }
  variable http
  ::http::config -useragent $http(agent)
  set qdata [::http::formatQuery $postdata]
  
  set r [catch {
    switch -- $type {
      "head" { set token [::http::geturl $query -command "[fqname]::http:callback $callback $id" -validate 1 -timeout $timeout] }
      "get" { set token [::http::geturl $query -command "[fqname]::http:callback $callback $id" -timeout $timeout] }
      "post" { set token [::http::geturl $query -command "[fqname]::http:callback $callback $id" -query $qdata -timeout $timeout] }      
      default { error "Unknown type specified: must be of head, get, post" }
    }
  } err]
  if {$r != 0} {
    error "Error: $err"
  }
  return
}
