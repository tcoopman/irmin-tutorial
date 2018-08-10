# Introduction

## What is Irmin?

`irmin` is a key-value store based on the same principles as git. It provides the ability to perform many interesting operations on stores like branching, merging and reverting. Typically Irmin is embedded into an OCaml application, but there are also several tools like [irmin-http](https://github.com/mirage/irmin), [irmin-graphql](https://github.com/andreas/irmin-graphql), [irmin-resp](https://github.com/zshipko/irmin-resp) that allow you to use it as a standalone server. In this introduction I will explain how to get started using both the library and the command-line tool.

## Getting started using the command-line

These examples require the `irmin-unix` package to be installed from [opam](https://github.com/ocaml/opam):

```shell
$ opam install irmin-unix
```

That will install a command line tool called `irmin`!

Once `irmin` is installed you can used it to create a new datastore and serve it over HTTP:

```shell
$ irmin --daemon --store mem --address http://127.0.0.1:8888
```

Or create a new store on-disk and manipulate it directly:

```shell
$ export EXAMPLE=/tmp/irmin/example
$ mkdir -p $EXAMPLE
$ irmin set "My key" "My value" --root $EXAMPLE
$ irmin get "My key" --root $EXAMPLE
My value
$ irmin remove "My key" --root $EXAMPLE
```

If you get sick of passing around `--root` all the time you can create a configuration file called `./irmin.yml` or `~/.irmin/config.yml` with options like:

```yaml
root: /tmp/irmin/example
store: git
content: string
```

See the output of `irmin help irmin.yml` for more details.

## Getting started using OCaml

Irmin has the ability to adapt to existing data structures using a convenient type combinator ([Irmin.Type](https://mirage.github.io/irmin/irmin/Irmin/Type/index.html)) to define ([Contents](https://mirage.github.io/irmin/irmin/Irmin/Contents/index.html)). Almost everything in `Irmin` is configurable including the hash function, branch, key and metadata types. Because of this there are a lot of different options to pick from; I will do my best to explain the most basic usage and work up from there.

In addition to the content type, you will also need to pick a storage backend. By default, Irmin provides a few options: an in-memory store, a filesystem store, a git-compatible in-memory store and a git-compatible filesystem store. Of course, it's also possible to implement your own storage backend.

Storage backends are all implemented as separate modules, the default backends are on opam as `irmin-mem`, `irmin-fs` and `irmin-git`. These packages define the way that the data should be organized, but not any I/O routines. Luckily, `irmin-unix` implements the I/O routines needed to make Irmin work on unix-like platforms and `irmin-mirage` provides the same for unikernels built using [Mirage](https://mirage.io).

Let's create a couple different stores:

```ocaml
(** An in-memory store with string contents *)
module Mem_store = Irmin_mem.KV(Irmin.Contents.String)
(** An on-disk git store with json contents *)
module Git_store = Irmin_unix.Git.FS.KV(Irmin.Contents.Json)
```

In this case I am using an [Irmin.KV]( https://mirage.github.io/irmin/irmin/Irmin/module-type-KV/index.html) store which is a specialization of [Irmin.S](https://mirage.github.io/irmin/irmin/Irmin/module-type-S/index.html) with string list keys, string branches and no metadata.

Before calling any functions, it is important to remember that most `Irmin` functions return `Lwt.t` values, which means that you will need to use `Lwt_main.run` to execute them. If you're not familiar with [Lwt](https://github.com/ocsigen/lwt) then I suggest [this tutorial](https://mirage.io/wiki/tutorial-lwt).

## Configuring and creating a repo

Different store types require different configuration options -- an on-disk store needs to know where it should be stored in the filesystem, however an in-memory store doesn't. This means that each storage backend implements its own configuration methods based on [Irmin.Private.Conf](https://mirage.github.io/irmin/irmin/Irmin/Private/Conf/index.html) - for the examples above there are `Irmin_mem.config`, `Irmin_fs.config` and `Irmin_git.config`, each taking slightly different parameters.

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

Once a repo has been created, you can access a branch and start to modify it.

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

Now, using everything I've laid out above, you can finally begin to read and write to the store using `get` and `set`.

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

## Inspecting the store

### Trees
### Commits
### History

In [the next section](/Contents) I will go into more detail about how to build custom content types.

