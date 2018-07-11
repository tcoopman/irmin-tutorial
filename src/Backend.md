# Writing a storage backend

In this section I will explain how to write a custom storage backend for `Irmin` using [irmin-redis](https://github.com/zshipko/irmin-redis) as an example. `irmin-redis` uses a Redis server to store Irmin data.

Unlike [custom datatypes](/Contents), there is not a tidy way of doing this. Each backend must fufil certain critera as defined by [Irmin.AO_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-AO_MAKER/index.html), [Irmin.LINK_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-LINK_MAKER/index.html), [Irmin.RW_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-RW_MAKER/index.html), [Irmin.S_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-S_MAKER/index.html), and [Irmin.KV_MAKER](https://mirage.github.io/irmin/irmin/Irmin/module-type-KV_MAKER/index.html). These module types define interfaces for functors that create stores. For example, a `KV_MAKER` defines a module that takes an `Irmin.Contents.S` as a parameter and returns a module of type `Irmin.KV`.

## Redis client

In this example we'll be using [hiredis](https://github.com/zshipko/ocaml-hiredis) to create connections, send and receive data from Redis servers. It is available on [opam](https://github.com/ocaml/opam) under the same name. 

## Defining the append-only store
