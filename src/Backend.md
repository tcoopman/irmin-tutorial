# Writing a storage backend

In this section I will explain how to write a custom storage backend for `Irmin` using a simplified implementation of [irmin-redis](https://github.com/zshipko/irmin-redis) as an example. `irmin-redis` uses a Redis server to store Irmin data.

Unlike [custom datatypes](/Contents), there is not a tidy way of doing this. Each backend must fulfil certain critera as defined by [Irmin.AO_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-AO_MAKER/index.html), [Irmin.LINK_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-LINK_MAKER/index.html), [Irmin.RW_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-RW_MAKER/index.html), [Irmin.S_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-S_MAKER/index.html), and [Irmin.KV_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-KV_MAKER/index.html). These module types define interfaces for functors that create stores. For example, a `KV_MAKER` defines a module that takes an `Irmin.Contents.S` as a parameter and returns a module of type `Irmin.KV`.

## Redis client

In this example we'll be using [hiredis](https://github.com/zshipko/ocaml-hiredis) to create connections, send and receive data from Redis servers. It is available on [opam](https://github.com/ocaml/opam) under the same name.

## The readonly store

The process for writing a backend for Irmin requires only a few steps. The first step is to define the interface for your readonly (`RO`) store.

The `RO` module type requires the following types to be defined:

- `t`: The store type
- `key`: The key type
- `value`: The value/content type

Additionally, it requires two functions:

- `mem`: checks whether or not a key exists
- `find`: returns the value associated with a key (if it exists)

```ocaml
open Hiredis
module RO (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  type t = Client.t
  type key = K.t
  type value = V.t
  let mem client key =
      let key = Fmt.to_to_string K.pp key in
      match Client.run client [| "EXISTS"; key |] with
      | Integer 1L -> Lwt.return_true
      | _ -> Lwt.return_false
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

Next, define the append-only (`AO`) interface:

```ocaml
module AO (K: Irmin.Hash.S) (V: Irmin.Contents.Conv) = struct
  include RO(K)(V)
  let add client value =
      let key = K.digest V.t value in
      let key' = Fmt.to_to_string K.pp key in
      let value = Fmt.to_to_string V.pp value in
      ignore (Client.run client [| "SET"; key'; value |]);
      Lwt.return key
end
```

### The link store

```ocaml
module Link (K: Irmin.Hash.S) = struct
  include RO(K)(K)
  let add client index key =
      let key = Fmt.to_to_string K.pp key in
      let index = Fmt.to_to_string K.pp index in
      ignore (Client.run client [| "SET"; index; key |]);
      Lwt.return_unit
end
```

## The read-write store

```ocaml
module RW (K: Irmin.Contents.Conv) (V: Irmin.Contents.Conv) = struct
  module RO = RO(K)(V)
  module W = Irmin.Private.Watch.Make(K)(V)
  type t = { t: RO.t; w: W.t }
  type key = RO.key
  type value = RO.value
  type watch = W.watch
  let watches = W.v ()
  let find t = RO.find t.t
  let mem t  = RO.mem t.t
  let watch_key t key = Fmt.pr "%a\n%!" K.pp key; W.watch_key t.w key
  let watch t = W.watch t.w
  let unwatch t = W.unwatch t.w
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
  let set {t = client; w} key value =
      let key' = Fmt.to_to_string K.pp key in
      let value' = Fmt.to_to_string V.pp value in
      match Client.run client [| "SET"; key'; value' |] with
      | Status "OK" -> W.notify w key (Some value)
      | _ -> Lwt.return_unit
  let remove {t = client; w} key =
      let key' = Fmt.to_to_string K.pp key in
      ignore (Client.run client [| "DEL"; key' |]);
      W.notify w key None
  let set' = set
  let test_and_set t key ~test ~set =
    find t key >>= fun v ->
    if Irmin.Type.(equal (option V.t)) test v then (
      (match set with
        | None -> remove t key
        | Some v -> set' t key v
      ) >>= fun () ->
      Lwt.return_true
    ) else (
      Lwt.return_false
    )
end
```
