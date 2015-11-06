
# https://en.wikipedia.org/wiki/URL_normalization

# RFC 2396 Format for Literal IPv6 Addresses in URL's
#
#      http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html
#      http://[1080:0:0:0:8:800:200C:417A]/index.html
#      http://[3ffe:2a00:100:7031::1]
#      http://[1080::8:800:200C:417A]/foo
#      http://[::192.9.5.5]/ipng
#      http://[::FFFF:129.144.52.38]:80/index.html
#      http://[2010:836B:4179::836B:4179]

# git usual URL syntaxe :
#   <scheme>://[<user>[:<pass>]@]<host>[:<port>][<uri>[?<args>]]
# git scp-like syntaxe :
#              [<user>[:<pass>]@]<host>[:<uri>[?<args>]]

# man git clone ;search="GIT URLS"
#	    ssh://[user@]host.xz[:port]/path/to/repo.git/
#	    git://host.xz[:port]/path/to/repo.git/
#	http[s]://host.xz[:port]/path/to/repo.git/
#	 ftp[s]://host.xz[:port]/path/to/repo.git/
#	  rsync://host.xz/path/to/repo.git/
# An alternative scp-like syntax may also be used with the ssh protocol:
#	         [user@]host.xz:path/to/repo.git/

url_join() {
	local r=""
	[ -n "$URL_SCHEME" ] && r="$URL_SCHEME://" || r='ssh://'
	[ -n "$URL_USER" ] && {
		r="${r}${URL_USER}"
		[ -n "$URL_PASS" ] && r="${r}:${URL_PASS}"
		r="${r}@"
	}
	r="${r}$URL_HOST"
	[ -n "$URL_PORT"   ] && r="${r}:$URL_PORT"
	[ -z "$URL_SCHEME" ] && [ -n "${URL_URI%%/*}" ] && r="${r}/"
	[ -n "$URL_URI"    ] && r="${r}$URL_URI"
	[ -n "$URL_ARGS"   ] && r="${r}?$URL_ARGS"
	printf '%s\n' "$r"
}

url_parse_user_pass() {
	local user_pass="$1"
	user="${user_pass%%:*}"   ;# [<user>]
        pass="${user_pass#*:}"    ;# [<pass>]
        [ "$pass" = "$user_pass" ] && pass=""           ;# no pass
}

url_parse_uri_args() {
	local uri_args="$1"
	uri="${uri_args%%\?*}"			;# [<uri>]
	args="${uri_args#*\?}"			;# [<args>]
	[ "$args" = "$uri" ] && args=""			;# no args
}
url_parse_port_uri_args_ipv6git() {
	local port_uri_args="$1"
	port=""
	uri_args="${port_uri_args#*:}"                          ;# [<uri>[?<args>]]
	[ "$uri_args" = "$port_uri_args" ] && uri_args=""       ;# empty uri
}
url_parse_port_uri_args_ipv6rfc() {
	local port_uri_args="$1"
	uri_args="${port_uri_args#*/}"				;# [<uri>[?<args>]]
	[ "$uri_args" = "$port_uri_args" ] && uri_args="" || uri_args="/$uri_args"	;# empty uri_args
	local host_port="${port_uri_args%%/*}"			;# <host>[:<port>]
	if [ "$(printf '%1c' "$port_uri_args")" = ':' ]; then
		port="${host_port##*:}"			;# [<port>]
		[ "$port" = "$host_port" ] && port=""		;# empty port
		#port="$port_uri_args%%/*}"			;# [<port>]
		#[ "$port" = "$port_uri_args" ] && port=""	;# empty port
	else
		port=""
	fi
}
url_parse_port_uri_args_ipv4git() {
	local port_uri_args="$1"
	# url = ...<host>:<uri...>
	host="${url3%:*}"					;# <host>
	port=""
	uri_args="${url3#*:}"					;# [<uri>[?<args>]]
	[ "$uri_args" = "$url3" ] && uri_args=""		;# empty uri
}
url_parse_port_uri_args_ipv4rfc() {
	local port_uri_args="$1"
	# url = ...<host>[:<port>]/<uri...>
	uri_args="${url3#*/}"					;# [<uri>[?<args>]]
	[ "$uri_args" = "$url3" ] && uri_args="" || uri_args="/$uri_args"	;# empty uri_args

	local host_port="${url3%%/*}"				;# <host>[:<port>]
	host="${host_port%:*}"					;# <host>
	port="${host_port##*:}"					;# [<port>]
	[ "$port" = "$host_port" ] && port=""			;# empty port
}

# potential bugs :
# - no scheme but URI or ARGS contains ://
# - URI doit contenir le premier / ou non ??

url_split() {
	local url="$1"; shift ;# https://user:pass@host:port/uri?args

	scheme="${url%%://*}"				;# <scheme>://...
	[ "$scheme" = "$url" ] && scheme=""		;# no scheme 

	local url2="$url"
	[ -n "$scheme" ] && url2="${url#*://}"		;# url without scheme = [<user>[:<pass>]@]<host>[:<port>][<uri>[?<args>]]

	local user_pass="${url2%%@*}"			;# [<user>[:<pass>]
	[ "$user_pass" = "$url2" ] && user_pass=""	;# no such user/pass

	url_parse_user_pass "$user_pass"

	local url3="${url2#*@}"				;# <host>[:<port>][<uri>[?<args>]]

	if [ "$(printf '%1c' "$url3")" = '[' ]; then
		# IPv6
		host="${url3%%]*}]"
		local port_uri_args="${url3#*]}"
		if [ -z "$scheme" ]; then
			url_parse_port_uri_args_ipv6git "$port_uri_args"
		else
			url_parse_port_uri_args_ipv6rfc "$port_uri_args"
		fi
	else
		# IPv4
		if [ -z "$scheme" ]; then
			url_parse_port_uri_args_ipv4git "$port_uri_args"
		else
			url_parse_port_uri_args_ipv4rfc "$port_uri_args"
		fi
	fi

	url_parse_uri_args "$uri_args"
}

url_split_export() {
	local url="$1"; shift ;# https://user:pass@host:port/uri?args

	local scheme user pass host port uri_args uri args
	url_split "$url"

	if [ "$1" = "--export" ]; then
		URL_SCHEME="$scheme"; URL_USER="$user"; URL_PASS="$pass"; URL_HOST="$host"; URL_PORT="$port"; URL_URI="$uri"; URL_ARGS="$args"
	else
		local fmt="$1"; shift
		[ -z "$fmt" ] && fmt='s=%s u=%s p=%s h=%s p=%s u=%s a=%s\n'
		printf "$fmt"  "$scheme"  "$user"  "$pass"  "$host"  "$port"  "$uri"  "$args"
	fi
}

