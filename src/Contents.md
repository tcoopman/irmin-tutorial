# Custom content types

At some point working with `Irmin` you will probably want to move beyond using the default content types. This section will explain how custom datatypes can be implemented using the `Irmin.Type` combinator. Before continuing with these examples make sure to read through the [official documentation](https://docs.mirage.io/irmin/Irmin/Type/index.html), which does a good job of outlining what types are defined and an overview of how theyre used.

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

## Object

In this example we will define an object type that maps string keys to string values. The type itself is not much more complicated, but the merge function will be much more involved.

```ocaml
module Object = struct
    type t = (string * string) list
    let t = Irmin.Type.(list (pair string string))
```

So far so good, Irmin provides a simple way to model a list of pairs!

```ocaml
	let pp = Irmin.Type.pp_json t
```

Now we're using `Irmin.Type.pp_json`, the predefined JSON pretty-printer, rather than writing our own. As types get more and more complex it is very nice to be able to use the JSON formatter to avoid having to write custom functions for encoding and decoding values.

```ocaml
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json t decoder
```

And `Irmin.Type.decode_json` to decode the JSON encoded string.

```ocaml
    let merge_object old a b =
    	let open Irmin.Merge.Infix in
        Irmin.Merge.conflict "not implemented"
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
            else merge_object old a b
        | None -> merge_object [] a b
    (* Define the merge operation using our merge function *)
    let merge = Irmin.Merge.(option (v t merge))
end
```

In the [next section](/Backend) I will cover how to write your own storage backend using [irmin-redis](https://github.com/zshipko/irmin-redis) as an example.
