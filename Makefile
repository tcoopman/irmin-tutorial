SRC=Introduction.md

check:
	bin/markdown-check-ocaml $(SRC) -l irmin-unix --vim

run:
	bin/markdown-check-ocaml $(SRC) -l irmin-unix --run
