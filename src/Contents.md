# Custom content types

At some point working with `Irmin` you will probably want to move beyond using string values. This section will explain how custom datatypes can be implemented using the `Irmin.Type` combinator.

Let's look at a few different types to get comfortable.

a tuple of type `string * int64`:

```ocaml
type t0 = string * int64
let t0 = Irmin.Type.(pair string int64)
```

a list of floats:

```ocaml
type t1 = float list
let t1 = Irmin.Type.(list float)

a record:

```ocaml
type t2 = {
    a: float;
    b: int;
    c: string;
}

let t2 =
    let open Irmin.Type in
    record "t2" (fun a b c -> {a; Int32.to_int b; c})
    |+ field "a" float (fun {a; _} -> a)
    |+ field "b" int32 (fun {b; _} -> Int32.of_int b)
    |+ field "c" string (fun {c; _} -> c)
    |> sealr
```

