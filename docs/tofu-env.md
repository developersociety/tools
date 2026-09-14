# Project environment variables

`dev tofu env` reads and sets the environment variables for a project. The workflow behind it
isn't obvious, which is why it gets a page of its own.

A project's environment variables live in the tofu state as `random_password` resources declared
in the project's `envvars.tf`. Reading and setting them used to mean copy-pasting raw
`tofu show -json | jq ...` and `state rm` / `import` incantations from the comments at the top of
each `envvars.tf`. Instead:

```console
$ dev tofu env                          # list every variable and its value
$ dev tofu env SENTRY_AUTH_TOKEN        # print one value
$ dev tofu env set SENTRY_AUTH_TOKEN    # prompt for the value, then import it
```

Three things to know:

- Setting a variable removes it from the state and re-imports it, so a `dev tofu apply` is still
  needed to get the new value onto the running service.
- The variable has to have a `random_password` resource in `envvars.tf` before it can be
  imported.
- Variables are told apart from tofu's internal passwords by their upper case names.
