# Introduction

## What is Irmin?

`irmin` is a datastore based on the same principles as git. It provides the ability to perform interesting operations on stores like branching, merging and reverting. Typically Irmin is embedded into an OCaml application, but there are also several tools like [irmin-http](https://github.com/mirage/irmin), [irmin-graphql](https://github.com/andreas/irmin-graphql), [irmin-resp](https://github.com/zshipko/irmin-resp) that allow you to use it as a server. In this introduction I will explain how to get started using both the library and the command-line tool.

## Getting started

1) Before you can create an `irmin` database you need to consider what type of data you will be storing. By default, Irmin provides implementations for `string`, `cstruct`, and `json` content types, but it's also possible to create your own with the [Irmin.Type](https://mirage.github.io/irmin/irmin/Irmin/Type/index.html) combinator.

The built-in content types can be found in [Irmin.Contents](https://mirage.github.io/irmin/irmin/Irmin/Contents/index.html) - for now we will stick to the `String` type, but the next section contains more information about building your own types.

2) Next you will want to consider how the data will be stored. Irmin provides a few options here: an in-memory store, a filesystem store,a git-compatible in-memory store and a git-compatible filesystem store. It's also possible to implement your own custom storage type -- as you may have noticed, most everything in Irmin is customizable even down to the the hash function!

Storage backends are implemented as separate modules, the default backends are on [opam](https://github.com/ocaml/opam) as `irmin-mem`, `irmin-fs` and `irmin-git`. These implementations define the way that the data should be organized, but do not define any I/O routines. `irmin-unix` provides an implementation of the required I/O routines needed to make Irmin work on unix-like platforms and `irmin-mirage` provides the same for unikernels built using [Mirage](https://mirage.io).

3) Putting it all together:

```ocaml
(** An in-memory store with string contents *)
module Mem_store = Irmin_mem.KV(Irmin.Contents.String)
(** An on-disk git store with string contents *)
module Git_store = Irmin_unix.Git.FS.KV(Irmin.Contents.String)
```

In this case we're using an [Irmin.KV]( https://mirage.github.io/irmin/irmin/Irmin/module-type-KV/index.html) store which is a subtype of [Irmin.S](https://mirage.github.io/irmin/irmin/Irmin/module-type-S/index.html) with string list keys, string branches and no metadata.

Before calling any functions, it is important to remember that most `Irmin` functions return `Lwt.t` values, this means that you will need to use `Lwt_main.run` to execute them. If you're not familiar with [Lwt](https://github.com/ocsigen/lwt) then I suggest [this tutorial](https://mirage.io/wiki/tutorial-lwt).

## Configuring and creating a repo

Before we are able to get access to the store, we will need to configure and create an [Irmin.Repo](https://mirage.github.io/irmin/irmin/Irmin/Repo/index.html). Different store types require different configuration. For instance, an on-disk store needs to know where it should be stored in the filesystem, however an in-memory store doesn't. Each storage backend implements its own configuration methods based on [Irmin.Private.Conf](https://mirage.github.io/irmin/irmin/Irmin/Private/Conf/index.html) - for the examples above there are `Irmin_mem.config`, `Irmin_fs.config` and `Irmin_git.config`, each taking slightly different parameters.

```ocaml
let git_config = Irmin_git.config ~bare:true "/tmp/irmin"
let config = Irmin_mem.config ()
```
Once you have created your configuration you can create an [Irmin.Repo](https://mirage.github.io/irmin/irmin/Irmin/Repo/index.html) using [Repo.v](https://mirage.github.io/irmin/irmin/Irmin/Make/Repo/index.html#val-v).

```ocaml
let git_repo = Git_store.Repo.v git_config
let repo = Mem_store.Repo.v config
```

## Using the repo to obtain access to a branch

Once a repo has been created, we are able to access a branch and start to modify it.

To get access to the `master` branch:

```ocaml
open Lwt.Infix

let master config =
    Mem_store.Repo.v config >>= Mem_store.master
```

To get access to a named branch:

```ocaml
let branch config name =
    Mem_store.Repo.v config >>= fun repo ->
    Mem_store.of_branch repo name
```

## Modifying the store

Now we are able to use everything I've shown you above to begin reading and writing contents. As shown below, once we have our repo set up we can use the `get` and `set` functions to read and modify the store.

```ocaml
let info message = Irmin_unix.info ~author:"Example" "%s"

let main =
Mem_store.Repo.v config >>= Mem_store.master >>= fun t ->

(* Set a/b/c to "Hello, Irmin!" *)
Mem_store.set t ["a"; "b"; "c"] "Hello, Irmin!" ~info:(info "my first commit") >>= fun () ->

(* Get a/b/c *)
Mem_store.get t ["a"; "b"; "c"] >|= fun s ->
assert (s = "Hello, Irmin!")

let _ = Lwt_main.run main
```

## Command-line

The command-line application, `irmin`, can be used to manage `irmin` stores from the command line. For example, the operations described above can be performed on a filesystem-backed Git store using the following commands:

```shell
$ mkdir mystore/
$ irmin set a/b/c "Hello, Irmin!" --root ./mystore --message "my first commit!" --author Example
$ irmin get a/b/c --root ./mystore
Hello, Irmin!
```

Since we're using the Git layout in this example it is possible to inspect the store using `git`! That means commands like `git log` and `git show` will work as expected.

In [the next section](/Contents) I will explain how to use custom contents types.

