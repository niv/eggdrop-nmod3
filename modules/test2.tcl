# this is a nmod3 test 

proc constructor {} {
	bind dcc - test dcc
}

proc destructor {} {
}



proc dcc {h i t} {
	putlog "i am in test now calling myglob"
	myglob
}
