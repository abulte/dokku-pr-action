# dokku-pr-action

Deploy your pull requests (PR) to dokku (eg review app).

This action handles the following events:
- PR opened or reopened: creates an app on dokku and deploy it
- PR synchronized (ie commits added): deploy the app
- PR closed: deletes the app

The created app will:
- have a name generated from the projet and PR, eg `{my-project}-refs-pull-{pr}-merge`
- will be accessible through HTTPS at `https://{my-project}-refs-pull-{pr}-merge.dokku.example.com` (this URL will be accessible via the `url` output, cf below)

Optionnaly the action can create a linked service (eg database) that will be automatically linked to your app. The service has the same name as the app. It will be removed when the PR is closed. See `LINKED_SERVICE` below.

If you simply want to deploy a branch to an existing dokku app, you can use [this action instead](https://github.com/vitalyliber/dokku-github-action).

## Usage

```
on:
  pull_request:
    types: [opened, synchronize, closed, reopened]

- name: dokku deploy
  id: deploy
  uses: abulte/dokku-pr-action@HEAD
  env:
    GITHUB_EVENT_ACTION: "${{ github.event.action }}"
    PRIVATE_KEY: ${{ secrets.PRIVATE_KEY }}
    HOST: dokku.example.com
    PROJECT: my-project
```

### Required Secrets

You'll need to provide some secrets to use the action.

- **PRIVATE_KEY**: An SSH private key which public key is allowed on dokku

### Required Environments

You'll need to provide some env to use the action.

- **HOST**: The host the action will SSH to run the git push command. ie, `your.site.com`.
- **PROJECT**: The project is Dokku project name.
- **PORT**: Port of the sshd listen to, `22` is set by default.
- **GITHUB_EVENT_ACTION**: `${{ github.event.action }}` result

### Optional Environments

You can optionally provide the following:

- **HOST_KEY**: The results of running `ssh-keyscan -t rsa $HOST`. Use this if you want to check that the host you're deploying to is the right one (e.g. has the same keys).
- **LINKED_SERVICE**: `mysql`, `postgres`, `mongo`... You need the corresponding plugins to be installed on dokku ([eg this one for postgres](https://github.com/dokku/dokku-postgres)). The plugins must honor the `:create` and `:destroy` CLI syntax.

### Output

#### url

`${{ steps.deploy.outputs.url }}` will contain the URL to the deployed app.

#### status

The Success/Failure of the action.

### Passing configuration variables to dokku

#### Standard variables

By commiting a `.env.dokku-pr` file at the root of your repo, the action will trigger `config:set` for all the variables defined there, at each deploy.

Example file:

```
TEST_CONFIG=a
TEST_CONFIG_2=b
```

Will execute `dokku config:set --no-restart {app} TEST_CONFIG=a TEST_CONFIG_2=b`.

#### Secret variables

Pro tip: you can even inject Github secrets.

In workflow definition:

```
  env:
    MY_SECRET: ${{ secrets.MY_SECRET }}
```

In `.env.dokku-pr`:

```
MY_SECRET=$MY_SECRET
```

## Advanced usage

[See this file for a full fledged example with github deployments included](example/preview.yml).

## Known limitations

### Reopening a PR

When reopening a PR, if some commits have been made after closing and before reopening, two jobs will be launched (`reopened` and `synchronize`) and one of them will fail (hopefully `synchronize`).

### TODO

- [x] handle linked service creation (eg a database)
- [x] handle setting some config var on dokku app
- [ ] release v1
