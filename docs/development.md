# Development

Please contribute! If you find yourself needing to do the same thing over and over, or you keep
forgetting a process, or you just feel you're typing too much to do boring stuff... then create a
script to automate/help/optimise it. And then we can all benefit.

## Tooling

The scripts are checked with shellcheck and formatted with shfmt:

```console
$ make install-local
$ make format
$ make lint
```

`make lint` is also what CI runs on every push.
