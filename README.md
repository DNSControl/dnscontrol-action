# dnscontrol-action

The Official Github Action (GHA) for DNSControl

This is a composite GitHub action for running configurable DNSControl commands.

[DNSControl](https://dnscontrol.org) is an [opinionated](https://docs.dnscontrol.org/developer-info/opinions) platform for seamlessly managing your DNS configuration across any number of DNS hosts, both in the cloud or in your own infrastructure.

### Action Features

* Write DNSControl output to PRs, job summary, and/or a file of your choosing
* Run (or don't) a "preflight" `dnscontrol check` before your command; check failure will stop the job and write to the job summary
* Specify alternate locations for `dnsconfig.js` and `creds.json`
* Choose which version of DNSControl to run (the default is the latest release)

## Credentials

Do NOT store API keys or other credentials in a git repo!

We recommend one of three methods:

- **Method 1: creds.json stored as a secret.** Stuff the entire `creds.json` file in a Github "secret".
- **Method 2: Dynamic creds.json file.** Store the individual credentials as github secrets, and dynamically generate the creds.json file that uses them.
- **Method 3: Static creds.json file.** Use a static creds.json file that references env variables for any secret.

See the comments in the file for setup instructions.

> [!WARNING]
> Secret values may be exposed in job logs when using environment variables to pass secrets. GitHub masks known secret values but debug logs or errors in GitHub's masking implementation may expose secret values. In short, populate your `creds.json` secrets and avoid writing secrets to environment variables if possible.

**Inputs**

* **cmdargs**: The command and flags you want to run (required)
* **dnsconfig_file**: The alternate location of `dnsconfig.js` (optional)
* **creds_file**: The alternate location of `creds.json` (optional)
* **output_file**: The file into which the command output should be written (optional)
* **post_pr_comment**: Post the command output to a PR comment (true/false, default is false)
* **post_summary**: Post the command output to the running job summary (true/false, default is false)

**Outputs**

* **output**: The output from the dnscontrol command you specified
* **output_file**: The workspace file (if you specified) into which output from the dnscontrol command was written

**Usage Example**

Example with all inputs set:

```yaml
name: DNSControl-Action
uses: DNSControl/dnscontrol-action
with:
  check: true
  cmdargs: preview --expect-no-changes
  creds_file: path/to/my-creds.json
  dnsconfig_file: path/to/my-dnsconfig.json
  output_file: dnscontrol-output.log
  post_pr_comment: true
  post_summary: true
```

**Simple DNSControl Preview Example**

See the `examples` directory for ready to use workflows. Run `dnscontrol preview` from a PR:

```yaml
name: DNSControl-Preview

on:
  pull_request:
    paths:
      - '*dnsconfig.js'
      - '*creds.json'
# FYI: The "on" statement for push/merge is very different. See examples/pr_push.yml.

permissions:
  contents: read
  pull-requests: write

jobs:
  preview:
    runs-on: ubuntu-latest
    if: ${{ !cancelled() }}
    steps:
      -
        name: Checkout repo
        uses: actions/checkout

      -
        # Extract the secret and write it to the file.
        name: Prepare creds_file
        run: printf '%s' '${{secrets.CREDS_JSON}}' > creds.json

      -
        name: call dnscontrol action
        uses: DNSControl/dnscontrol-action
        with:
          cmdargs: preview
          post_pr_comment: true
          post_summary: true
          check: true
```

## Contributing

PRs welcome!

Changes or additions to the shell scripts and action `run` steps must pass `bin/shellcheck.sh`. Any findings at warning or error levels will fail the check. The wrapper script has been tested in Bash 5.2 and zsh 5.9 on Linux and MacOS.

### Testing

To assist with troubleshooting changes, debug output can be enabled:

```yaml
uses: DNSControl/dnscontrol-action
env:
  DEBUG_ACTION: true
with:
  cmdargs: ...
```

New debug statements can be added to the action by using `$DEBUG` in place of `echo`
```shell
... other code ...
$DEBUG "new output here"
...
```