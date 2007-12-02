# SQL abstraction

proc nmod {} {
	return {
		{ "author" "Bernard 'Elven' Stoeckner" }
		{ "contact" "elven@swordcoast.net" }
		{ "licence" "GPLv2" }
		{ "version" "2006102901" }
		{ "description" "[dummy] mysql abstraction using mysqltcl" }
	}
}

load /usr/lib/mysqltcl-3.02/libmysqltcl3.02.so

# package require mysqltcl 3

proc constructor {} {
#	foreach c {
#		connect use sel fetch exec
#		query endquery map receive
#		seek col info baseinfo ping
#		changeuser result
#		state close insertid
#		escape autocommit commit
#		rollback nextresult moreresult
#		warningcount isnull
#		newnull setserveroption
#		shutdown encoding
#} {
#		register_global ::mysql::$c 0
#	}
}

proc destructor {} {
	# package forget mysqltcl
}

# Creates a sql connection by specifying a ODBC string
proc db:create {odbc} {
	
}

proc db:close {handle} {

}

proc mysql:prepare {} {

}
