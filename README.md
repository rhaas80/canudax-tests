GitHub Actions based tests for CanudaX
=======================================

## Running locally

The tests run inside of a Docker container using image
einsteintoolkit/carpetx-test:latest to reduce build time for CarpetX
dependencies.

To run them in a local copy of the container image do:

```
sudo docker pull einsteintoolkit/carpetx-test:latest
sudo docker run -it einsteintoolkit/carpetx-test /bin/bash -i

git clone -b main https://github.com/rhaas80/canudax-tests.git scripts
git clone -b gh-pages https://github.com/rhaas80/canudax-tests.git gh-pages

bash scripts/bin/build-and-test.sh
```

You may want to disable sending email by commenting out the

```
os.system(f"python3 {dir}/mail.py {REPO}")
```

line in `bin/logpage.py`.

## Triggering automated builds

The actions workflow is set up to be triggered by a webhook that needs to be
called by a BitBucket pipeline and needs to have an access token stored in
bitbucket of a user that cna trigger the workflow.

The `bitbucket-pipelines.yml` file to be put into CanudaX looks like this:

```
image: atlassian/default-image:3

pipelines:
  default:
    - step:
        name: 'Build and Test'
        script:
          - >
            curl -H "Accept: application/vnd.github.everest-preview+json" -H "Authorization: token $TRIGGER_TOKEN" --request POST --data '{"event_type": "webhook", "client_payload": {"trigger":"'$BITBUCKET_COMMIT'"}}' https://api.github.com/repos/rhaas80/canudaxx-tests/dispatches
```

`TRIGGER_TOKEN` is a bitbucket repository variable
(https://bitbucket.org/canuda/canudax_lean/admin/addon/admin/pipelines/repository-variables)
that stores the access token obtained for GitHub (from
https://github.com/settings/tokens?type=beta).
