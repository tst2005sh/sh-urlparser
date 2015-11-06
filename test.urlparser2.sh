
. ./urlparser.sh

t() {
	local scheme user pass host port uri_args uri args
	url_split "$1"
	printf -- '- %s (original)\n  %s (parsed, splited, recontructed)\n\n' "$1" "$(url_join)"

}
t "https://github.com/tst2005/sh-urlparser/"
t "ssh://git@github.com/tst2005/sh-urlparser.git"
t "git@github.com:tst2005/sh-urlparser.git"

