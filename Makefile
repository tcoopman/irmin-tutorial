MDX_PATH=mdx

build: check
	mdbook build

check:
	$(MDX_PATH) pp src/Introduction.md > src/book.ml
	$(MDX_PATH) pp src/Contents.md  >> src/book.ml
	$(MDX_PATH) pp src/UsingTheCommandLine.md >> src/book.ml
	$(MDX_PATH) pp src/GettingStartedOCaml.md >> src/book.ml
	$(MDX_PATH) pp src/Backend.md  >> src/book.ml
	ocamlbuild -pkg irmin-unix -pkg hiredis src/book.native
