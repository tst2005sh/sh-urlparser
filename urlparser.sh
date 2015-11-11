
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
	local toformat
	case "$1" in
		rfc|git) toformat="$1" ;;
		*)
			echo >&2 "invalid format $1. must be 'rfc' or 'git'."
			return 1
	esac

	local r
	case "$toformat" in
		git)
			if [ -n "$URL_PORT" ]; then
				echo >&2 "git format does not support to provide a port number (URL_PORT us not empty)"
				return 1
			fi
			r=""
		;;
		rfc) r="${URL_SCHEME:-ssh}://" ;;
	esac
	r="${r}${URL_USER:-}${URL_PASS:+:$URL_PASS}"
	if [ -n "$URL_USER" ] || [ -n "$URL_PASS" ]; then
		r="${r}@"
	fi
	case "$URL_HOST" in
		*:*)	# IPv6, host inside []
			r="${r}[${URL_HOST:-}]"
		;;
		*)	# not IPv6
			r="${r}${URL_HOST:-}"
	esac
	case "$toformat" in
		git)	;;
		rfc)
			r="${r}${URL_PORT:+:$URL_PORT}"
		;;
	esac
	case "$toformat" in
		git) r="${r}:" ;;
		rfc)
			if [ -n "${URL_HOST}" ]; then
				if [ -n "${URL_URI:-}" ] || [ -n "${URL_ARGS:-}" ]; then
					r="${r}/"
				fi
			fi
		;;
	esac
	r="${r}${URL_URI:-}${URL_ARGS:+?$URL_ARGS}"
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
	uri="${uri_args%%\?*}"				;# [<uri>]
	args="${uri_args#*\?}"				;# [<args>]
	[ "$args" = "$uri" ] && args=""			;# no args
}

url_parse_port_uri_args_rfc() {
	local url="$1"						;# url = ...<host>[:<port>]/<uri...>
	local isipv6="$2"

	if $isipv6; then
		host="${url%%\]*}"; host="${host#\[}" ;# trim '[' and ']' from host
		local port_uri_args="${url#*\]}"	;# cut after the first ']'

		uri_args="${port_uri_args#*/}"				;# [<uri>[?<args>]]
		#[ "$uri_args" = "$port_uri_args" ] && uri_args="" || uri_args="/$uri_args"	;# empty uri_args
		local host_port="${port_uri_args%%/*}"			;# <host>[:<port>]
		if [ "$(printf '%1c' "$port_uri_args")" = ':' ]; then
			port="${host_port##*:}"				;# [<port>]
			[ "$port" = "$host_port" ] && port=""		;# empty port
		else
			port=""
		fi
	else
		case "$url" in
			/*)	uri_args="$url" ;;
			*)	uri_args="${url#*/}"					;# [<uri>[?<args>]]
		esac
		#[ "$uri_args" = "$url" ] && uri_args="" || uri_args="/$uri_args"	;# empty uri_args

		local host_port="${url%%/*}"				;# <host>[:<port>]
		host="${host_port%:*}"					;# <host>
		port="${host_port##*:}"					;# [<port>]
		[ "$port" = "$host_port" ] && port=""			;# empty port
	fi
}

url_parse_port_uri_args_git() {
	local url="$1"
	local isipv6="$2"

	if $isipv6; then
		host="${url%%\]*}"; host="${host#\[}"		;# <host> without '[' and ']'
		uri_args="${url#*\]:}"
	else
		host="${url%%:*}"				;# <host>
		uri_args="${url#*:}"				;# [<uri>[?<args>]]
	fi
	port=""							;# port (always) empty
	[ "$uri_args" = "$url" ] && uri_args=""			;# empty uri
}

# potential bugs :
# - no scheme but URI or ARGS contains ://
# - URI doit contenir le premier / ou non ??

url_split() {
	local url="$1"; shift ;# https://user:pass@host:port/uri?args

	local scheme="${url%%://*}"			;# <scheme>://...
	[ "$scheme" = "$url" ] && scheme=""		;# no scheme

	[ -z "$scheme" ] || url="${url#*://}"		;# url without scheme = [<user>[:<pass>]@]<host>[:<port>][<uri>[?<args>]]

	local user_pass="${url%%@*}"			;# [<user>[:<pass>]
	[ "$user_pass" = "$url" ] && user_pass=""	;# no such user/pass

	local user pass
	url_parse_user_pass "$user_pass"

	local url3="${url#*@}"				;# <host>[:<port>][<uri>[?<args>]]

	local isipv6 ;# its IPv6 if url3 startwith '['
	[ -z "${url3%%\[*}" ] && isipv6=true || isipv6=false

	local host port uri_args
	if [ -z "$scheme" ]; then
		url_parse_port_uri_args_git "$url3" $isipv6
	else
		url_parse_port_uri_args_rfc "$url3" $isipv6
	fi

	local uri args
	url_parse_uri_args "$uri_args"

	URL_SCHEME="$scheme"; URL_USER="$user"; URL_PASS="$pass"; URL_HOST="$host"; URL_PORT="$port"; URL_URI="$uri"; URL_ARGS="$args"
}

url_split_debug() {
	local url="$1"; shift ;# https://user:pass@host:port/uri?args
	#local URL_SCHEME URL_USER URL_PASS URL_HOST URL_PORT URL_URI URL_ARGS
	url_split "$url"

	local fmt="$1"; shift
	[ -z "$fmt" ] && fmt='s=%s u=%s p=%s h=%s p=%s u=%s a=%s\n'
	printf "$fmt"  "$URL_SCHEME"  "$URL_USER"  "$URL_PASS"  "$URL_HOST"  "$URL_PORT"  "$URL_URI"  "$URL_ARGS"
}

