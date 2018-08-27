# Introduction

## What is Irmin?

`irmin` is a key-value store based on the same principles as git. It provides the ability to perform many interesting operations on stores like branching, merging and reverting. Typically Irmin is embedded into an OCaml application, but there are also several tools like [irmin-http](https://github.com/mirage/irmin), [irmin-rpc](https://github.com/zshipko/irmin-rpc), [irmin-graphql](https://github.com/andreas/irmin-graphql), [irmin-resp](https://github.com/zshipko/irmin-resp) that allow you to use it as a standalone server.

## What can I use it for?

It is typically used to store application data, like configuration values, shared state or checkpoint snapshots, but can be used as a general purpose key-value store too. Since it is compatible with Git, `irmin` can be used to interact with git repositories directly from your application.
