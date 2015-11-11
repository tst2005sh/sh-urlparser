
. ./urlparser.sh

t() {
	local URL_SCHEME URL_USER URL_PASS URL_HOST URL_PORT URL_URI URL_ARGS URL_URI_ARGS
	url_split "$1"
	printf -- '- %s (original)\n  %s (parsed, splited, recontructed)\n' "$1" "$(url_join "rfc")"
	echo ""
}
t "https://github.com/tst2005/sh-urlparser/"
t "ssh://git@github.com/tst2005/sh-urlparser.git"
t "git@github.com:tst2005/sh-urlparser.git"
t 'http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html'
