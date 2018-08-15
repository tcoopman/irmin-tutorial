# irmin-tutorials

A collection of examples for [irmin](https://github.com/mirage/irmin).

## Dependencies

- [ocamlbuild](https://github.com/ocaml/ocamlbuild)
- [mdx](https://github.com/realworldocaml/mdx)
    - `opam pin add mdx https://github.com/realworldocaml/mdx.git`
- [irmin-unix](https://github.com/mirage/irmin)
    - `opam install irmin-unix`
- [ocaml-hiredis](https://github.com/zshipko/ocaml-hiredis)
    - `opam install hiredis`
- [mdBook](https://github.com/rust-lang-nursery/mdBook)
    - requires Rust/Cargo
    - `cargo install mdbook`

## Building

All that's needed is:

```shell
$ make
```

This will check the code embedded in the `.md` files and build an HTML version of the tutorials in `./book`

## Contributing

Contributions are encouraged! If you think something is missing or could be explained better please open a pull-request.
