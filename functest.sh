#!/bin/sh

# cmp pour comparer 2 fichiers ?
# [1] ok        : parfait : le resultat correspond au spec
# [2] nok       : bug     : le resultat ne correspond pas et ce n'est pas voulu/prévu
# [3] almost ok : toleré  : le resultat est faux mais c'est connu/voulu/pas grave
# test_strict # test_approx # test_differ #

# W 123
# IGN 123.0
# IGN 0123
# TEST + RESULT


test_result() {
	local st="$1" ; shift
	local w="$1" ; shift
	local g="$1" ; shift
	case "$st" in
		PASS)	printf '[%s] test-%03d : %s%s\n' "$st" "$TESTSUITE_NUMBER" "$TESTSUITE_TITLE" "${1:+ ($1)}" ;;
		FAIL)
			printf '[%s] test-%03d : %s%s' "$st" "$TESTSUITE_NUMBER" "$TESTSUITE_TITLE" "${*:+ ($*)}"
			printf %20s ''
			printf "wanted '%.8s' but got '%.8s'"\\n "$w" "$g"
		;;
	esac
}

DISABLE() { :; }
RESET() { TESTSUITE_IGN=''; TESTSUITE_WANTED=''; }

TITLE() { TESTSUITE_TITLE="$*"; }
N() {
	case "$1" in
		""|init) TESTSUITE_NUMBER=1 ;;
		"++")	TESTSUITE_NUMBER=$(( $TESTSUITE_NUMBER + 1 )) ;;
		*)	TESTSUITE_NUMBER="$1"
	esac
}

IGNORE() {
	TESTSUITE_IGN="${TESTSUITE_IGN:+$TESTSUITE_IGN:}$1"
}

ignore_forcepass() {
	local igns="$TESTSUITE_IGN"
	while [ -n "$igns" ]; do
		local ign="${igns%%:*}"
		if [ "$1" = "$ign" ] || [ "$(printf %8s "$1")" = "$ign" ]; then
			return 0
		fi
		[ "$ign" = "$igns" ] && break
		igns="${igns#*:}"
	done
	return 1
}

internalsum() {
	local sum="$(md5sum)"
        printf %s\\n "${sum%% *}"
}
SUM() { internalsum; }
SUMVALUE() { printf %s\\n "$1" | internalsum; }

### WANTED value
WANTED() {
	if [ -n "$1" ]; then
		TESTSUITE_WANTED="$(printf %s\\n "$1" | internalsum)"
	else
		TESTSUITE_WANTED="$(internalsum)"
	fi
}
W()  { WANTED "$@"; }



PIPE_SUM_EQUAL_TO() {
	local want="$1" ; shift
	local got="$(internalsum)"
	local st=FAIL
	if [ "$want" = "$got" ] || ignore_forcepass "$got"; then
		st=PASS
	fi
	test_result "$st" "$want" "$got" "$@"
}

PIPE_VALUE_EQUAL_TO() {
	local want="$1" ; shift
	local got="$(IFS='';cat -)"
	[ -z "$IFS" ] && echo >&2 "IFS est propagé oulala"
	local st=FAIL
	if [ "$want" = "$got" ] || ignore_forcepass "$got"; then
		st=PASS
	fi
	test_result "$st" "$want" "$got" "$@"
}

### TEST the VALUE
TESTVALUE() {
	local got="$1"; shift
	local st=FAIL
	if [ "$TESTSUITE_WANTED" = "$got" ] || ignore_forcepass "$(SUMVALUE "$got")"; then
		st=PASS
	fi
	test_result "$st" "$TESTSUITE_WANTED" "$got" "$@"
}
TV() { TESTVALUE "$@"; }

### TEST the return code
#TESTRETURN() {
#	eval "$@" >/dev/null 2>&1
#	local v=$?
#	internaltestvalue false "$v"
#	TESTSUITE_NUMBER=$(( $TESTSUITE_NUMBER + 1 ))
#}
#TR() { TESTRETURN "$@"; }

BUFFER() {
	case "$1" in
		stdout)  echo "${TMPFILE_OUT:=$(mktemp /tmp/functest.$1.XXXX || exit 1)}" ;;
		stderr)  echo "${TMPFILE_ERR:=$(mktemp /tmp/functest.$1.XXXX || exit 1)}" ;;
		retcode) echo "${TMPFILE_RET:=$(mktemp /tmp/functest.$1.XXXX || exit 1)}" ;;
		*) error
	esac
}

main() {
	N init
	for testfile in "$@"; do
		case "$testfile" in
			/*) ;;
			*) testfile="./$testfile"
		esac
		TESTFILE="$testfile" \
		. "$testfile"
	done
}
main "$@"
