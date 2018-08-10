MDX_PATH=mdx

check:
	$(MDX_PATH) pp src/Introduction.md > src/book.ml
	$(MDX_PATH) pp src/Contents.md  >> src/book.ml
	$(MDX_PATH) pp src/Backend.md  >> src/book.ml
	ocamlbuild -pkg irmin-unix -pkg hiredis src/book.native

run:
	bin/markdown-check-ocaml $(SRC) -l irmin-unix --run
