build:
	odin build .

debug:
	odin build . -debug

run:
	make build
	./csv_viewer test.csv

test:
	odin test .
