build:
	odin build .

run:
	make build
	./csv_viewer test.csv

test:
	odin test .
