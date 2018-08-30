# Introduction

[Irmin](https://github.com/mirage/irmin) is a key-value store written in OCaml, based on the same principles as Git. To existing Git users, it provides many familiar features: branching/merging, history and the ability to restore to any previous state.

Typically Irmin is embedded into an OCaml application, but there are also several tools like [irmin-http](https://github.com/mirage/irmin), [irmin-rpc](https://github.com/zshipko/irmin-rpc), [irmin-graphql](https://github.com/andreas/irmin-graphql), [irmin-resp](https://github.com/zshipko/irmin-resp) that allow you to use it as a standalone server.

It is most often used to store application data, like configuration values, shared state or checkpoint data, but can be used as a general purpose key-value store too. Since it is compatible with Git, Irmin can also be used to interact with Git repositories directly from your OCaml application.

Take a moment to skim the [README](https://github.com/mirage/irmin/blob/master/README.md) to familiarize yourself with some of the concepts. Also, if you find that anything is missing or unclear in this tutorial then please file [an issue](https://github.com/zshipko/irmin-tutorial/issues)!
