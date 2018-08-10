# Custom content types

At some point working with `Irmin` you will probably want to move beyond using the default content types. This section will explain how custom datatypes can be implemented using [Irmin.Type](https://mirage.github.io/irmin/irmin/Irmin/Type/index.html). Before continuing with these examples make sure to read through the [official documentation](https://docs.mirage.io/irmin/Irmin/Type/index.html), which does a good job of outlining what types are defined and an overview of how theyre used.

Now let's create a custom type and define the functions required by [Irmin.Contents.S](https://docs.mirage.io/irmin/Irmin/Contents/module-type-S/index.html) using a simple datatype and then another more complex example after.

## Counter

```ocaml
module Counter: Irmin.Contents.S with type t = int64 = struct
	type t = int64
	let t = Irmin.Type.int64
```

A counter is just a simple `int64` value that can be incremented and decremented. Luckily Irmin already defines and `int64` type so we don't have to define our own.

Next we will need to define some functions for converting to and from strings.

```ocaml
	let pp fmt = Format.fprintf fmt "%Ld"
```

`pp` defines a pretty-printer for our type.

```ocaml
	let of_string s =
		match Int64.of_string_opt s with
		| Some i -> Ok i
		| None -> Error (`Msg "invalid counter value")
```

And `of_string` is used to convert a formatted string back to our original type. It returns ```(t, [`Msg of string]) result```, which allows for an error message to be passed back to the user if the string is invalid.

Finally, we need to define a merge function. For our counter type we can just add the values when merging, this is a much simplier situation than you will encounter but was picked to illustrate a very simple case. Typically when writing a merge function you will need to deal with how to handle conflicts, this will be covered in the example after this one.

```ocaml
	let merge ~old a b =
		Lwt.return (Ok (Int64.add a b))
```

```ocaml
    let merge = Irmin.Merge.(option (v t merge))
```

```ocaml
end
```

Now this `Counter` module can be used as the contents of an Irmin store:

```ocaml
module Counter_mem_store = Irmin_mem.KV(Counter)
```

## Record

Now let's wrap a record type so it can be stored directly in Irmin.

Here is a `car` type that we will use as content type for our store. The key type will be VIN numbers, so maybe this is a list of clients for an automotive repair shop.

```ocaml
type color =
    | Black
    | White
    | Other of string
and car = {
    license: string;
    year: int32;
    make_and_model: string * string;
    color: color;
}
```

Now let's turn it into a representation that Irmin will understand! First color has to be wrapped, variants are modeled using the `variant` function:

```ocaml
module Car: Irmin.Contents.S with type t = car = struct
    type t  = car
    let color =
        let open Irmin.Type in
        variant "color" (fun black white other -> function
            | Black -> black
            | White -> white
            | Other color -> other color)
        |~ case0 "Black" Black
        |~ case0 "White" White
        |~ case1 "Other" string (fun s -> Other s)
        |> sealv
```

This is mapping variant cases to their names in string representation. Records are handled similarly:

```ocaml
    let car =
        let open Irmin.Type in
        record "car" (fun license year make_and_model color ->
            {license; year; make_and_model; color})
        |+ field "license" string (fun t -> t.license)
        |+ field "year" int32 (fun t -> t.year)
        |+ field "make_and_model" (pair string string) (fun t -> t.make_and_model)
        |+ field "color" color (fun t -> t.color)
        |> sealr
```

Finally, we can use the builtin JSON encoding and merge function:

```ocaml
	let pp = Irmin.Type.pp_json car
```

This example uses `Irmin.Type.pp_json`, the predefined JSON pretty-printer, rather than writing our own. As types get more and more complex it is very nice to be able to use the JSON formatter to avoid having to write custom functions for encoding and decoding values.

```ocaml
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json car decoder
```

And the merge operation:

```ocaml
    let merge = Irmin.Merge.(option (idempotent car))
end
```

## Object

In this example we will define an object type that maps string keys to string values. The type itself is not very complicated, but the merge function is.

```ocaml
module Object = struct
    type t = (string * string) list
    let t = Irmin.Type.(list (pair string string))
```

So far so good, Irmin provides a simple way to model a list of pairs! Now we can use the JSON encoder again, just like in the previous example.

Define `pp`:

```ocaml
	let pp = Irmin.Type.pp_json t
```

And `of_string`:

```ocaml
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json t decoder
```

Then we can leverage `Irmin.Merge.alist` to define a merge function for associative lists. In this case we are using strings for both the keys and values, however `alist` requires you to have written merge functions for both the key and value types so it can get quite complicated depending on your types. For a slightly more complicated example you can look at `merge_object` and `merge_value` in [contents.ml](https://github.com/mirage/irmin/blob/master/src/irmin/contents.ml), which implements JSON contents for Irmin.

```ocaml
    let merge_object ~old x y =
        let open Irmin.Merge.Infix in
        let m = Irmin.Merge.(alist Irmin.Type.string Irmin.Type.string (fun _key -> option string)) in
        Irmin.Merge.(f m ~old x y) >>=* fun x' -> Irmin.Merge.ok x'
```

`merge_object` is a 3-way merge function for our object type. It ensures that a key will not be overwritten by a merge, but allows new keys to be added.

```ocaml
    let merge ~old a b =
        let open Irmin.Merge.Infix in
        let equal = Irmin.Type.equal t in
        old () >>=* function
        | Some old ->
            if equal old a then Irmin.Merge.ok b
            else if equal old b then Irmin.Merge.ok a
            else merge_object (fun () -> Irmin.Merge.ok (Some old)) a b
        | None -> merge_object (fun () -> Irmin.Merge.ok None) a b
    (* Define the merge operation using our merge function *)
    let merge = Irmin.Merge.(option (v t merge))
end
```

Now you should be ready to follow along with the [custom_merge](https://github.com/mirage/irmin/blob/master/examples/custom_merge.ml) example in the Irmin repository.
