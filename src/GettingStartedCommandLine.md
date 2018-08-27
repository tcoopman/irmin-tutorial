# Getting started using the command-line

These examples require the `irmin-unix` package to be installed from [opam](https://github.com/ocaml/opam):

```shell
$ opam install irmin-unix
```

After that is finished you should have the `irmin` binary installed! To get a list of commands run:

```shell
$ irmin help
```

Now you can do things like create an in-memory store and serve it over HTTP:

```shell
$ irmin --daemon --store mem --address http://127.0.0.1:8888
```

Or create a new store on-disk and manipulate it directly from the terminal:

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

