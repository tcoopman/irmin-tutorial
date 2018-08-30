# Introduction

## What is Irmin?

`irmin` is a key-value store written in OCaml, based on the same principles as git. To users of git, it provides many familiar features: branching/merging and the ability to restore to any previous state. Typically Irmin is embedded into an OCaml application, but there are also several tools like [irmin-http](https://github.com/mirage/irmin), [irmin-rpc](https://github.com/zshipko/irmin-rpc), [irmin-graphql](https://github.com/andreas/irmin-graphql), [irmin-resp](https://github.com/zshipko/irmin-resp) that allow you to use it as a standalone server.

The [irmin repository](https://github.com/mirage/irmin) also gives a good high-level explanation of what it is and how to get started.

## What can I use it for?

It is typically used to store application data, like configuration values, shared state or checkpoint data, but can be used as a general purpose key-value store too. Since it is compatible with git, `irmin` can also be used to interact with git repositories directly from your OCaml application.
