# dokku-pr-action

Deploy your pull requests (PR) to dokku (eg review app).

This action handles the following events:
- PR opened or reopened: creates an app on dokku and deploy it
- PR synchronized (ie commits added): deploy the app
- PR closed: deletes the app

The created app will:
- have a name generated from the projet and PR, eg `{my-project}-refs-pull-{pr}-merge`
- will be accessible through HTTPS at `https://{my-project}-refs-pull-{pr}-merge.dokku.example.com` (this URL will be accessible via the `url` output, cf below)

If you simply want to deploy a branch to an existing dokku app, you can use [this action instead](https://github.com/vitalyliber/dokku-github-action).

## Usage

```
# deploy app
- name: dokku deploy
  id: deploy
  uses: abulte/dokku-pr-action@HEAD
  env:
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

### Optional Environments

You can optionally provide the following:

- **HOST_KEY**: The results of running `ssh-keyscan -t rsa $HOST`. Use this if you want to check that the host you're deploying to is the right one (e.g. has the same keys).

### Output

#### url

`${{ steps.deploy.outputs.url }}` will contain the URL to the deployed app.

#### status

The Success/Failure of the action.

## Known limitations

### Reopening a PR

When reopening a PR, if some commits have been made after closing and before reopening, two jobs will be launched (`reopened` and `synchronized`) and one of them will fail (hopefully `synchronized`)

### TODO

- [ ] handle linked service creation (eg a database)
