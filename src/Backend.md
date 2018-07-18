# Writing a storage backend

In this section I will explain how to write a custom storage backend for `Irmin` using a simplified implementation of [irmin-redis](https://github.com/zshipko/irmin-redis) as an example. `irmin-redis` uses a Redis server to store Irmin data.

Unlike [custom datatypes](/Contents), there is not a tidy way of doing this. Each backend must fufil certain critera as defined by [Irmin.AO_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-AO_MAKER/index.html), [Irmin.LINK_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-LINK_MAKER/index.html), [Irmin.RW_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-RW_MAKER/index.html), [Irmin.S_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-S_MAKER/index.html), and [Irmin.KV_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-KV_MAKER/index.html). These module types define interfaces for functors that create stores. For example, a `KV_MAKER` defines a module that takes an `Irmin.Contents.S` as a parameter and returns a module of type `Irmin.KV`.

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

