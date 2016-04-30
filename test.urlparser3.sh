
. ./urlparser.sh

t() {
	local URL_SCHEME URL_USER URL_PASS URL_HOST URL_PORT URL_URI URL_ARGS URL_URI_ARGS
	url_split "$1"
	printf -- '- %s (original)\n  %s (parsed, splited, recontructed)\n' "$1" "$(url_join "rfc")"
	export URL_SCHEME URL_USER URL_PASS URL_HOST URL_PORT URL_URI URL_ARGS URL_URI_ARGS; printenv | grep ^URL_
	#printf 'URL_HOST=%s\n' "$URL_HOST"
	echo ""
}

t 'git@github.com:tst2005/lua-lockbox.git'
#t '://git@github.com:tst2005/lua-lockbox.git'
t 'ssh://git@github.com/tst2005/lua-lockbox.git?#arg=git@github.com:tst2005/lua-lockbox.git'

t 'git@github.com:tst2005/lua-lockbox.git?#arg=git@github.com:tst2005/lua-lockbox.git'

t 'file:///tmp/123'
