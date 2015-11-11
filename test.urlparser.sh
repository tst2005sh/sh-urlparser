#!/bin/sh

. "$(dirname -- "$0")/functest.sh"
. "$(dirname -- "$0")/urlparser.sh"

maketest() {
	local fmt='1=%s\n2=%s\n3=%s\n4=%s\n5=%s\n6=%s\n7=%s\n'
	local fmtinline='scheme=%s user=%s pass=%s host=%s port=%s path=%s args=%s\n'
	for h1_url in \
'5ac5f04a9680f9acddbd6f14d88698db=http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html' \
'51cefc5a44de1ec5f1d88e2ceb25e130=http://[1080:0:0:0:8:800:200C:417A]/index.html' \
'473c54d555cfb8f6b9a2953aef9fab6a=http://[3ffe:2a00:100:7031::1]' \
'01c8c1e042e48df775cf6227b87356b0=http://[1080::8:800:200C:417A]/foo' \
'5131a3b08103c888695f15989701efad=http://[::192.9.5.5]/ipng' \
'a59c7801c6904551ec6639c368f5fcd9=http://[::FFFF:129.144.52.38]:80/index.html' \
'549593c33c1760aa0150e05d869b9fbd=http://[2010:836B:4179::836B:4179]' \
'4ffa7b7869dd4bcc7a0628f9e7c77181=user:pass@host' \
'4ffa7b7869dd4bcc7a0628f9e7c77181=user:pass@host:' \
'3685e10e056c0a0bc32603f631d02c03=user:pass@host:xx/yy' \
'c887cc0ccf6afe5e19e82d397cbe4681=user:pass@[::1]:xx/yy:zz' \
'd8e9de0f8370242de13829e659041d82=https://user:pass@[::1]:443/path/to/get?truc:machin#an' \
'b7a20cff17d1f5ede82d4f4217f141c1=https://user:pass@host:port/uri' \
'z1=http://host?xxx=yyy/zzz' \
'z2=http://[host]?xxx=yyy/zzz' \
	; do
		local h1="${h1_url%%=*}"
		local url="${h1_url#*=}"
		local v="$(url_split_debug "$url" "$fmt")"
		printf -- '-%s\n' "$url"
		url_split_debug "$url" "+$fmtinline"

		continue
#
#		W "$..."
#		TESTVALUE "$url"
#
#		local h2="$(printf '%s\n' "$v" | md5sum)"
#		h2="${h2%% *}"
#		[ "$h1" = "$h2" ] && echo "ok: $url" || {
#			echo "FAIL: $url ($h1 != $h2)";
#			url_split_debug "$url" "$fmt"
#		}
#		url_split "$url"
#		local url2="$(url_join "rfc")"
#		if [ "$url" != "$url2" ]; then
#			echo >&2 "- $url"
#			echo >&2 "+ $url2"
#		fi
#		#printf >&2 '%s\n' "$v"
done
}


test_one() {
	local url="$1"; shift
	local want="$1"; shift
	local fmtinline='scheme=%s user=%s pass=%s host=%s port=%s path=%s args=%s\n'
	W "$want"
	TESTVALUE "$(SUMVALUE "$(url_split_debug "$url" "$fmtinline")")" "$url" || {
		echo "  original url = '$url'"
		echo "  $(url_split_debug "$url" "$fmtinline")"
		#url_split "$url"
		#export URL_SCHEME URL_USER URL_PASS URL_HOST URL_PORT URL_URI URL_ARGS
		#printenv | grep ^URL_
	}
	N ++
}



maketest2() {
	test_one 'http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html' \
		'scheme=http user= pass= host=FEDC:BA98:7654:3210:FEDC:BA98:7654:3210 port=80 path=index.html args='

	test_one 'http://[1080:0:0:0:8:800:200C:417A]/index.html' \
		'scheme=http user= pass= host=1080:0:0:0:8:800:200C:417A port= path=index.html args='

	test_one 'http://[3ffe:2a00:100:7031::1]' \
		'scheme=http user= pass= host=3ffe:2a00:100:7031::1 port= path= args='

	test_one 'http://[1080::8:800:200C:417A]/foo' \
		'scheme=http user= pass= host=1080::8:800:200C:417A port= path=foo args='

	test_one 'http://[::192.9.5.5]/ipng' \
		'scheme=http user= pass= host=::192.9.5.5 port= path=ipng args='

	test_one 'http://[::FFFF:129.144.52.38]:80/index.html' \
		'scheme=http user= pass= host=::FFFF:129.144.52.38 port=80 path=index.html args='

	test_one 'http://[2010:836B:4179::836B:4179]' \
		'scheme=http user= pass= host=2010:836B:4179::836B:4179 port= path= args='

	test_one 'user:pass@host' \
		'scheme= user=user pass=pass host=host port= path= args='

	test_one 'user:pass@host:' \
		'scheme= user=user pass=pass host=host port= path= args='

	test_one 'user:pass@host:xx/yy' \
		'scheme= user=user pass=pass host=host port= path=xx/yy args='

	test_one 'user:pass@[::1]:xx/yy:zz' \
		'scheme= user=user pass=pass host=::1 port= path=xx/yy:zz args='

	test_one 'https://user:pass@[::1]:443/path/to/get?truc:machin#an' \
		'scheme=https user=user pass=pass host=::1 port=443 path=path/to/get args=truc:machin#an'

	test_one 'https://user:pass@host:port/uri' \
		'scheme=https user=user pass=pass host=host port=port path=uri args='

	test_one 'http://host?xxx=yyy/zzz' \
		'scheme=http user= pass= host=host port= path= args=?xxx=yyy/zzz'

	test_one 'http://[ho:st]?xxx=yyy/zzz' \
		'scheme=http user= pass= host=ho:st port= path= args=xxx=yyy/zzz'

	test_one 'file:///tmp/123' \
		'scheme=file user= pass= host= port= path=/tmp/123 args='
}

case "$1" in
	-)
	while read -r url; do
		[ -z "$url" ] && continue
		echo "url=$url -> $(_uri_split "$url")"
	done
	exit
	;;
esac
maketest2

