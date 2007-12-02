# this is a nmod3 test

depend_on eggdropcore

proc constructor {} {
	bind dcc - test test
}

proc destructor {} {
}

proc test {h i t} {
	putlog "variable nick is $::nick"
}