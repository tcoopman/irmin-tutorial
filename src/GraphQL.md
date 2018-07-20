# GraphQL API

[irmin-graphql](https://github.com/andreas/irmin-graphql) provides a GraphQL server for reading from and writing to Irmin stores. This tutorial will give you an idea of how to use `irmin-graphql` to query and Irmin store using any GraphQL client.

## Reading and writing values

This are the simpliest types of queries/mutations you can perform using the GraphQL API.

To get a key:

```graphql
# Setup the query
query {
    # Access the master branch
    master {
        # Get the key 'abc'
        get(key: "abc") {
            value
        }
    }
}
```

and to set a key:

```graphql
# Setup the mutation
mutation {
    set(branch: null, key: "abc", value: "123", info: null)
}
```

In the `set` example above, `branch: null` tells the server to use the default, or `master` branch. The `info` parameter can be used to set the commit author and message.
