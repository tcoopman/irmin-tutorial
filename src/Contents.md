# Custom content types

At some point working with `Irmin` you will probably want to move beyond using the default content types. This section will explain how custom datatypes can be implemented using [Irmin.Type](https://mirage.github.io/irmin/irmin/Irmin/Type/index.html). Before continuing with these examples make sure to read through the [official documentation](https://docs.mirage.io/irmin/Irmin/Type/index.html), which does a good job of outlining what types are defined and an overview of how they're used.

Now that you've read through the documentation, let's create a custom type and define the functions required by [Irmin.Contents.S](https://docs.mirage.io/irmin/Irmin/Contents/module-type-S/index.html). I will show you a few examples:

- [Counter](#counter)
- [Record](#record)
- [Association list](#association-list)

## Overview

To create a content type you need to define the following:

- A type `t`
- A value `t` of type `Irmin.Type.t`
- A function `pp` for formatting `t`
- A function `of_string` for converting from `string` to `t`
- A function merge, which performs a three-way merge

## Counter

A counter is just a simple `int64` value that can be incremented and decremented, when counters are merged the values will be added together.

To get started, you will need to define a type `t` and build a value `t` using the functions provided in [Irmin.Type](https://docs.mirage.io/irmin/Irmin/Type/index.html). In this case all we need is the existing `int64` value, but in most cases it won't be this simple!

```ocaml
module Counter: Irmin.Contents.S with type t = int64 = struct
	type t = int64
	let t = Irmin.Type.int64
```

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

And `of_string` is used to convert a formatted string back to our original type. It returns ```(t, [`Msg of string]) result```, which allows for an error message to be passed back to the user if the value is invalid.

Finally, we need to define a merge function.  There is already a `counter` implementation available in [Irmin.Merge](https://docs.mirage.io/irmin/Irmin/Merge/index.html), so you will never need to implement this yourself.

```ocaml
	let merge ~old a b =
	    let open Irmin.Merge.Infix in
		old () >|=* fun old ->
        let old = match old with None -> 0L | Some o -> o in
        let (+) = Int64.add and (-) = Int64.sub in
        a + b - old
```

```ocaml
    let merge = Irmin.Merge.(option (v t merge))
end
```

If we were to leverage the existing implementation it would be even simpler:

```ocaml
let merge = Irmin.Merge.(option counter)
```

Now this `Counter` module can be used as the contents of an Irmin store:

```ocaml
module Counter_mem_store = Irmin_mem.KV(Counter)
```

## Record

In this example I will wrap a record type so it can be stored directly in Irmin.

Here is a `car` type that we will use as content type for our store:

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
    owner: string;
}
```

Next it needs to be modeled using `Irmin.Type` before it can be stored using Irmin.

First color has to be wrapped, variants are modeled using the `variant` function:

```ocaml
module Car = struct
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
    let t =
        let open Irmin.Type in
        record "car" (fun license year make_and_model color owner ->
            {license; year; make_and_model; color; owner})
        |+ field "license" string (fun t -> t.license)
        |+ field "year" int32 (fun t -> t.year)
        |+ field "make_and_model" (pair string string) (fun t -> t.make_and_model)
        |+ field "color" color (fun t -> t.color)
        |+ field "owner" string (fun t -> t.owner)
        |> sealr
```

Finally, we can use the builtin JSON encoding and merge function:

```ocaml
	let pp = Irmin.Type.pp_json t
```

This example uses `Irmin.Type.pp_json`, the predefined JSON pretty-printer, rather than writing our own. As types get more and more complex it is very nice to be able to use the JSON formatter to avoid having to write ad-hoc functions for encoding and decoding values.

```ocaml
    let of_string s =
        let decoder = Jsonm.decoder (`String s) in
        Irmin.Type.decode_json t decoder
```

And the merge operation:

```ocaml
    let merge = Irmin.Merge.(option (idempotent t))
end
```

Now some examples using `Car` -- we will map VIN numbers to cars, this could be used by a tow company or an auto shop to identify cars:

```ocaml
module Car_store = Irmin_mem.KV(Car)

let car_a = {
    color = Other "green";
    license = "ABCD123";
    year = 2002;
    make_and_model = ("Honda", "Accord");
    owner = "Jane Doe";
}

let car_b = {
    color = Black;
    license = "MYCAR00";
    year = "2016";
    make_and_model = ("Toyota", "Corolla");
    owner = "Mike Jones";
}

let add_car store vin car =
    Car_store.set store [vin] car

let main =
    let config = Irmin_mem.config () in
    Car_store.Repo.v config >>= Car_store.master >>= fun t ->
    add_car t "5Y2SR67049Z456146" car_a >>= fun () ->
    add_car t "2FAFP71W65X110910" car_b >>= fun () ->
    Car_store.get t "2FAFP71W65X110910" >|= fun car ->
    assert (car.license = car_a.license);
    assert (car.year = car_a.year)

let () = Lwt.run main
```

## Association list

In this example we will define an association list that maps string keys to string values. The type itself is not very complicated, but the merge function is even more complex than the previous two examples.

Like the two examples above, you need to define a `t` type and a `t` value of type `Irmin.Type.t` to begin:

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

Finally, we can leverage `Irmin.Merge.alist` to define a merge function for associative lists. In this case we are using strings for both the keys and values, however `alist` requires you to have written merge functions for both the key and value types so it can get quite complicated depending on your types. For a slightly more complicated example you can look at `merge_object` and `merge_value` in [contents.ml](https://github.com/mirage/irmin/blob/master/src/irmin/contents.ml), which implements JSON contents for Irmin.


```ocaml
    let merge_alist =
        Irmin.Merge.(alist Irmin.Type.string Irmin.Type.string (fun _key -> option string))
    let merge = Irmin.Merge.(option merge_alist)
end
```

If still want another example then check out the [custom merge](https://github.com/mirage/irmin/blob/master/examples/custom_merge.ml) example in the Irmin repository, which illustrates how to write a mergeable log.
