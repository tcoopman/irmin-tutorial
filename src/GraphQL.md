# GraphQL API

[irmin-graphql](https://github.com/andreas/irmin-graphql) provides a GraphQL server for reading from and writing to Irmin stores. This tutorial will give you an idea of how to use `irmin-graphql` with [irmin.js](https://github.com/zshipko/irmin-js) to query an Irmin store.

## Getting started with irmin-js

- Clone the repository
    * `git clone https://github.com/zshipko/irmin-js`

## Initializing the client

The first thing you need to do when using `irmin.js` is to initialize a client. In order to do that you will need to know the URL for your GraphQL endpoint. Unfortunately, `irmin-graphql` does not accept cross-origin requests so you will need to use another server like nginx or Caddy to proxy requests to the GraphQL server.

```javascript
var ir = new Irmin("http://localhost:8000/graphql");
```

Now the client is ready to use!

## Reading and writing values

To get a key from the `master` branch:

```javascript
ir.get(key).then((value) => ...);
```

and to set a key on the master branch:

```javascript
ir.set(key, value).then((response) => ...);
```

Both functions take an optional `branch` argument to allow branches other than `master` to be used.
