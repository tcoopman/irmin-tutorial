# Getting started using the command-line

## Installation

These examples requires the `irmin-unix` package to be installed from [opam](https://github.com/ocaml/opam):

```shell
$ opam install irmin-unix
```

After that is finished you should have the `irmin` binary installed! To get a list of commands run:

```shell
$ irmin help
```

## Working with stores

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

## Configuration

If you get sick of passing around `--root` all the time you can create a configuration file called `./irmin.yml` or `~/.irmin/config.yml` with global configuration options:

```yaml
root: /tmp/irmin/example
store: git
content: string
```

See the output of `irmin help irmin.yml` for a list of configurable parameters.

## Git compatibility

`irmin` and `git` can be used interchangeably for certain commands, for instance here are some examples of operations that can be achieved using either git or Irmin.

### Cloning a remote repository

```shell
$ irmin clone $GIT_REPO_URL
```

```shell
$ git clone $GIT_REPO_URL
```

### Restoring to a previous commit

```shell
$ irmin revert $COMMIT_HASH
```

```shell
$ git reset --hard $COMMIT_HASH
```

### Pushing to a remote repository

```shell
$ irmin push $GIT_REPO_URL
```

```shell
$ git push $GIT_REPO_URL master
```

As you can see, the command-line application has many capabilities, but it's just a fraction of what's available when using Irmin from OCaml! For more information about using Irmin and OCaml, check out the [next section](GettingStartedOCaml.html).
