# dict.cc script (c) 2008 by thommey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

proc constructor {} {
	package require http
	bind pub - !dict translate_pub
}

proc nmod {} {
	return {
		{ "author" "thommey" }
		{ "licence" "GPLv2" }
		{ "version" "1" }
		{ "description" "query dict.cc" }
	}
}

proc html2text {html} {
	regsub -all -- {(\\|\[)} $html {\\\1} text
	regsub -all -- "&#0{0,2}(\\d+);" $text {[format %c \1]} text
	set text [subst -novariables $text]
	return [string map [list {&iquest;} {¿} {&auml;} {ä} {&Auml;} {Ä} {&ouml;} ö {&Ouml;} {Ö} {&uuml;} ü {&Uuml;} {Ü} {&szlig;} {ß} \
	{</b>} {} {<b>} {} {&apos;} \' {&quot;} \" {&bdquo;} \" {&lsquo;} \' {&ndash;} {-} {&eacute;} {é} {&euml;} e \
	{&eagrave;} {è} {&iuml;} {ï} {&amp;} {&} {&nbsp;} { } {&gt;} {>} {&lt;} {<} {&diams;} {*} {&euro;} {€} \
	{&copy;} {©} {&trade;} {™} {&iexcl;} {¡} {&cent;} {¢} {&pound;} {£} {&sect;} {§} {&uml;} \" \
	{&plusmn;} {±} {&sup2;} {²} {&sup3;} {³} {&acute;} \' {&micro;} {µ} {&para;} {¶} {&middot;} {·} \
	{&frac14;} {¼} {&frac12;} {½} {&frac34;} {¾} {&bull;} {/}] $text]
}

# This is a workaround around nmods wonky bind procname handling. It does not accept
# proc names with parameters pre-supplied in the bind.
proc translate_pub {args} {
	eval [concat [list translate pub] $args]
}

proc translate {type args} {
	if {$type == "pub"} {
		set target [lindex $args 3]; #channel
	} else {
		set target [lindex $args 0]; #nick
	}
	set tok [http::geturl http://pocket.dict.cc/?[http::formatQuery s [lindex $args end]]]
	if {[http::status $tok] != "ok"} {
		putmsg $target "meep. http-error: [http::code $tok]"
		http::cleanup $tok
		return
	}
	set results [regexp -all -inline {<TR><TD bgcolor="#[ed]{6}"><font size="2"><b>(.+?) </b><br>(.+?)</font>} [http::data $tok]]
	http::cleanup $tok
	if {![llength $results]} {
		putmsg $target "nothing found"
		return
	}
	set result ""
	set shown 0
	foreach {crap eng ger} $results {
		regsub -all -- {<.+?>} $eng {} eng
		regsub -all -- {<.+?>} $ger {} ger
		set ger [string trim $ger]; set eng [string trim $eng]
		if {$shown > 5} { break }
		append result "\00303[html2text $eng]\003 - \00305[html2text $ger]\003 | "
		incr shown
	}
	set result [string range $result 0 end-3]; #strip off " | "
	putmsg $target $result
}
