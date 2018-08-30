MDX_PATH=mdx
MDBOOK:=`which mdbook`

build: check
ifndef MDBOOK
	echo "WARNING: mdBook not installed, not buildint HTML output"
else
	mdbook build
endif

check:
	$(MDX_PATH) pp src/Introduction.md > src/book.ml
	$(MDX_PATH) pp src/Contents.md  >> src/book.ml
	$(MDX_PATH) pp src/UsingTheCommandLine.md >> src/book.ml
	$(MDX_PATH) pp src/GettingStartedOCaml.md >> src/book.ml
	$(MDX_PATH) pp src/Backend.md  >> src/book.ml
	ocamlbuild -pkg irmin-unix -pkg hiredis src/book.native

run: check
	./book.native
