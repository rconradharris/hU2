default:
	echo No default

side-load:
	./tools/side-load hU2.prg

side-load-fast:
	FAST=1 ./tools/side-load hU2.prg

tail-log:
	./tools/tail-log

clear-logs:
	./tools/clear-logs
