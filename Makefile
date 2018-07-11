check:
	mdx pp src/Introduction.md > src/book.ml
	mdx pp src/Contents.md  >> src/book.ml
	ocamlbuild -pkg irmin-unix src/book.native

run:
	bin/markdown-check-ocaml $(SRC) -l irmin-unix --run
