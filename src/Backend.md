# Writing a storage backend

In this section I will explain how to write a custom storage backend for `Irmin` using a simplified implementation of [irmin-redis](https://github.com/zshipko/irmin-redis) as an example. `irmin-redis` uses a Redis server to store Irmin data.

Unlike writing a [custom datatype](Contents.html), there is not a tidy way of doing this. Each backend must fulfill certain criteria as defined by [Irmin.AO_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-AO_MAKER/index.html), [Irmin.LINK_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-LINK_MAKER/index.html), [Irmin.RW_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-RW_MAKER/index.html), [Irmin.S_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-S_MAKER/index.html), and [Irmin.KV_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-KV_MAKER/index.html). These module types define interfaces for functors that create stores. For example, a `KV_MAKER` defines a module that takes an `Irmin.Contents.S` as a parameter and returns a module of type `Irmin.KV`.

## Redis client

In this example we'll be using [hiredis](https://github.com/zshipko/ocaml-hiredis) to create connections, send and receive data from Redis servers. It is available on [opam](https://github.com/ocaml/opam) under the same name.

## The readonly store

The process for writing a backend for Irmin requires only a few steps. The first step is to define the interface for your readonly ([RO](https://mirage.github.io/irmin/irmin/Irmin/module-type-RO/index.html)) store.

The [RO](https://mirage.github.io/irmin/irmin/Irmin/module-type-RO/index.html) module type requires the following types to be defined:

- `t`: The store type
- `key`: The key type
- `value`: The value/content type

```ocaml
open Lwt.Infix
open Hiredis
```

```ocaml
module RO (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  type t = Client.t (* Store type *)
  type key = K.t    (* Key type *)
  type value = V.t  (* Value type *)
```

Additionally, it requires two functions:

- `mem`: checks whether or not a key exists
- `find`: returns the value associated with a key (if it exists)

`mem` is implemented using the `EXISTS` command, which checks for the exitence of a key in Redis:

```ocaml
  let mem client key =
      let key = Fmt.to_to_string K.pp key in
      match Client.run client [| "EXISTS"; key |] with
      | Integer 1L -> Lwt.return_true
      | _ -> Lwt.return_false
```

`find` uses the `GET` command to retreive and key, if one isn't found or can't be decoded correctly then `find` returns `None`:

```ocaml
  let find client key =
      let key = Fmt.to_to_string K.pp key in
      match Client.run client [| "GET"; key |] with
      | String s ->
          (match V.of_string s with
          | Ok s -> Lwt.return_some s
          | _ -> Lwt.return_none)
      | _ -> Lwt.return_none
end
```

### The append-only store

Next is the append-only ([AO](https://mirage.github.io/irmin/irmin/Irmin/module-type-AO/index.html)) interface - the majority of the required methods can be inherited from `RO`!

```ocaml
module AO (K: Irmin.Hash.S) (V: Irmin.Contents.Conv) = struct
  include RO(K)(V)
```

We just need to implement a single function called `add`, which is used to create an association between hashes and values and returns the hash:

```ocaml
  let add client value =
      let hash = K.digest V.t value in
      let key = Fmt.to_to_string K.pp hash in
      let value = Fmt.to_to_string V.pp value in
      ignore (Client.run client [| "SET"; key; value |]);
      Lwt.return hash
end
```

### The link store

The [Link](https://mirage.github.io/irmin/irmin/Irmin/module-type-LINK/index.html) store creates verified links between low-level keys:

```ocaml
module Link (K: Irmin.Hash.S) = struct
  include RO(K)(K)
```

This `add` function is different from the one w ejust implemented because it takes two keys rather than a single value:

```ocaml
  let add client index key =
      let key = Fmt.to_to_string K.pp key in
      let index = Fmt.to_to_string K.pp index in
      ignore (Client.run client [| "SET"; index; key |]);
      Lwt.return_unit
end
```

## The read-write store

The [RW](https://mirage.github.io/irmin/irmin/Irmin/module-type-RW/index.html) store has many more types and values that need to be defined, but luckilly this is the last step! We will start of by using the `RO` functor we defined above to create a `RO` module:

```ocaml
module RW (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  module RO = RO(K)(V)
```

There are a few types we need to declare next. `key` and `value` should match `RO.key` and `RO.value` and `watch` is used to declare the type of the watcher -- this is used to send notifications when the store has been updated. [irmin-watcher](https://github.com/mirage/irmin-watcher) has some more information if you're curious.

```ocaml
  module W = Irmin.Private.Watch.Make(K)(V)
  type t = { t: RO.t; w: W.t }  (* Store type *)
  type key = RO.key             (* Key type *)
  type value = RO.value         (* Value type *)
  type watch = W.watch          (* Watch type *)
```

The `watches` variable defined below creates a context used to track active watches.

```ocaml
  let watches = W.v ()
```

The next few functions (`find` and `mem`) are just wrappers around the implementations in `RO`:

```ocaml
  let find t = RO.find t.t
  let mem t  = RO.mem t.t
```

A few more simple functions: `watch_key`, `watch` and `unwatch`, used to created or destroy watches:

```ocaml
  let watch_key t key = W.watch_key t.w key
  let watch t = W.watch t.w
  let unwatch t = W.unwatch t.w
```

Finally, we will need to implement some functions ourselves:

- `list`, lists files at a specific path.
- `set`, writes a value to the store.
- `remove`, deletes a value from the store.
- `test_and_set`, writes a value to the store only if the `test` value matches the current value for the given key.

Our `list` implementation will get a list of keys from Redis using the `KEYS` command then convert them from strings to `Store.key` values:

```ocaml
  let list {t = client; _} =
      match Client.run client [| "KEYS"; "*" |] with
      | Array arr ->
          Array.map (fun k ->
            K.of_string (Value.to_string k)
          ) arr
          |> Array.to_list
          |> Lwt_list.filter_map_s (function
            | Ok s -> Lwt.return_some s
            | _ -> Lwt.return_none)
      | _ -> Lwt.return []
```

```ocaml
  let set {t = client; w} key value =
      let key' = Fmt.to_to_string K.pp key in
      let value' = Fmt.to_to_string V.pp value in
      match Client.run client [| "SET"; key'; value' |] with
      | Status "OK" -> W.notify w key (Some value)
      | _ -> Lwt.return_unit
```

```ocaml
  let remove {t = client; w} key =
      let key' = Fmt.to_to_string K.pp key in
      ignore (Client.run client [| "DEL"; key' |]);
      W.notify w key None
```

```ocaml
  let test_and_set t key ~test ~set:s =
    find t key >>= fun v ->
    if Irmin.Type.(equal (option V.t)) test v then (
      (match s with
        | None -> remove t key
        | Some v -> set t key v
      ) >>= fun () ->
      Lwt.return_true
    ) else (
      Lwt.return_false
    )
end
```
