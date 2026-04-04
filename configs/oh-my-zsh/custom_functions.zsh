# Back Up a file. Usage "backup filename.txt"
function backup() {
	cp $1 ${1}_`date +%Y%m%d%H%M%S`.backup
}

# Prints the http status code of a url passed as parameter
function httpstatus() {
	code=$(curl -s -o /dev/null -I -w "%{http_code}" $1)
	echo "$1 status: $code"
}
