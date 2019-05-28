# B2B Asset Pipeline Demonstration

## Configuration

### Obtain your Service Account Key

In the Shell, run `gcloud config set project <PROJECT_ID> && gcloud iam service-accounts keys create ./credentials/runner.json --iam-account <SERVICE_ACCOUNT_EMAIL>`, where:

* `PROJECT_ID` is the GCP project ID that you created the service account in; and
* `SERVICE_ACCOUNT_EMAIL` is the assigned email address of the service account Terraform will run as (see [README.md](README.md) for details on necessary permissions).

For the purposes of this demonstration, the command is `gcloud config set project h5g-infrastructure && gcloud iam service-accounts keys create ./credentials/runner.json --iam-account terraform-jenkins@rmg-assets.iam.gserviceaccount.com`. Alternatively, provide the credential file out-of-band.

### Download the Docker image

In the Shell, run `docker pull gcr.io/h5g-infrastructure/h5g-b2b-pipeline-deployment-manager:cli` to pull down the Docker image to run the [deployment manager](http://bitbucket.high5.local/projects/BBIN/repos/h5g-b2b-pipeline-deployment-manager/browse).

### Configure Git

Configure the Shell-local `git` client by running:

```
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```

### Nexus Artifact Configuration

Confirm that the following assets are present in the `berlinsky-h5g-demo` Nexus repository at `35.193.73.84`:

- `nyx-nj-int`: NYX NJ integration assets
- `pp-gib-int`: PP GIB integration assets
- `gg`: Golden Goddess game assets
- `sotf`: Secrets of the Forest game assets

Stubs of each of these assets can be found in [./demo-assets](./demo-assets/).

### DNS Delegation

Ensure that `FQDN` is delegated to the DNS zone set in [configuration.py](http://bitbucket.high5.local/projects/BBIN/repos/h5g-b2b-pipeline-deployment-manager/browse/b2b_pipeline_deployment_manager/configuration.py) in GCP.

## Initial Deployment

### Migrating

We'll start by deploying:

| Nexus Asset | Version | Description                       | Target Environment(s) |
|-------------|---------|-----------------------------------|-----------------------|
| nyx-nj-int  | 1.0     | NYX NJ Integration Assets         | nyx-nj                |
| pp-gib-int  | 1.0     | PP GIB Integration Assets         | pp-gib                |
| gg          | 1.0     | Golden Goddess Game Assets        | nyx-nj, pp-gib        |
| sotf        | 1.0     | Secrets of the Forest Game Assets | nyx-nj, pp-gib        |

The migration to do this initial deployment is defined in `./migration_templates/01.yaml`. For the purpose of demonstration, we'll run this migration manually, not with Jenkins. To run the initial deployment:

1. Activate the migration: `cp ./migration_templates/01.yaml ./migrations/01.yaml`
2. Run the pipeline manager to generate a deterministic pipeline, and associated Terraform configuration: `docker run -v "$(pwd)"/migrations:/migrations -v "$(pwd)"/pipeline:/pipeline -v "$(pwd)"/hcl:/hcl gcr.io/h5g-infrastructure/h5g-b2b-pipeline-deployment-manager:cli --migration-dir=/migrations --pipeline-output-file=/pipeline/b2b-asset-pipeline.yaml --hcl-output-dir=/hcl`
3. Execute the generated HCL: `cd hcl && (GOOGLE_APPLICATION_CREDENTIALS=../credentials/runner.json terraform init && GOOGLE_APPLICATION_CREDENTIALS=../credentials/runner.json terraform apply); cd -`
4. Commit the generated pipeline and migrations: `git commit migrations/ pipelines/ && git commit -m "Demonstration phase 1" && git push origin head`.

### Verification

Note that GCLBs may take up to 10 minutes to activate for the first time. Once they are active, the following URLs should resolve as expected, and display the correct version (note that because the SSL certificate is stubbed and self-signed, you will need to run `curl` with the `-k` argument):

- `curl -k https://nj-nyx.qa.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.int-test.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.stage.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://gib-pp.qa.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://gib-pp.int-test.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://gib-pp.stage.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://gib-pp.games.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.qa.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.int-test.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.stage.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.qa.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.int-test.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.stage.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.games.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nyx-nj.qa.h5grgs.co/VERSION.txt`
- `curl -k https://nyx-nj.int-test.h5grgs.co/VERSION.txt`
- `curl -k https://nyx-nj.stage.h5grgs.co/VERSION.txt`
- `curl -k https://nyx-nj.h5grgs.co/VERSION.txt`
- `curl -k https://pp-gib.qa.h5grgs.co/VERSION.txt`
- `curl -k https://pp-gib.int-test.h5grgs.co/VERSION.txt`
- `curl -k https://pp-gib.stage.h5grgs.co/VERSION.txt`
- `curl -k https://pp-gib.h5grgs.co/VERSION.txt`

### Jenkins Automation and Idempotency

Jenkins is configured to run on commits made to the `master` branch (note that for now, the jobs are not automatically executed, and require clicking "Build Now" in the Jenkins UI for the job. Integrating automatic execution on push is omitted). It automates steps (2) (3) and (4) as outlined above. Given that we just executed the migration, running Jenkins at this time should be idempotent. To confirm this, navigate to the [Jenkins job](https://gcp-jenkins.high5games.com/job/B2B/job/Assets/job/B2B%20Asset%20Deployment%20Pipeline/job/master/) and click "Build Now." The job should conclude with the output `No changes. Infrastructure is up-to-date.`. We will demonstrate Jenkins executing the pipeline in the next step.

## Deploying New Game Assets

We now wish to deploy *Golden Goddess version 2.0*, only to `nyx-nj`, across all of `QA`, `int-test`, `stage` and `prod`.

### Migrating

The migration to perform this operation is defined in `./migration_templates/02.yaml`. To run this deployment:

1. Activate the migration: `cp migration_templates/02.yaml ./migrations/02.yaml`
2. Commit the migration so Jenkins picks up on it: `git add ./migrations/02.yaml && git commit -m "Demonstration phase 2" && git push origin head`
3. Navigate to the [Jenkins job](https://gcp-jenkins.high5games.com/job/B2B/job/Assets/job/B2B%20Asset%20Deployment%20Pipeline/job/master/) and click "Build Now"
4. When prompted, approve the execution of the Terraform plan.

### Verification

Once the Terraform plan has been applied:

1. Observe that the generated idempotent pipeline has been committed back to the [repository](http://bitbucket.high5.local/projects/BBIN/repos/b2b-asset-pipeline-demo/browse)
2. Observe that the following return version 2.0, as expected:
- `curl -k https://nj-nyx.qa.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.int-test.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.stage.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.h5grgs.co/gg/VERSION.txt`
3. Observe that the following still return version 1.0, as expected:
- `curl -k https:/gib-pp.qa.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.int-test.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.stage.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.qa.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.int-test.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.stage.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.qa.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.int-test.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.stage.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.h5grgs.co/sotf/VERSION.txt`

## Game Asset Retirement

We now wish to deploy *Golden Goddess version 2.0* to all `pp-gib` as well as `nyx-nj`, across all of `QA`, `int-test`, `stage` and `prod`. This will obviate the version 1.0 deployment, and we can confirm that it is deleted in the non-production environments, and set to `COLDLINE` in production-like environments.

### Migrating

The migration to perform this operation is defined in `./migration_templates/03.yaml`. To run this deployment:

1. Activate the migration: `cp migration_templates/03.yaml ./migrations/03.yaml`
2. Commit the migration so Jenkins picks up on it: `git add ./migrations/03.yaml && git commit -m "Demonstration phase 3" && git push origin head`
3. Navigate to the [Jenkins job](https://gcp-jenkins.high5games.com/job/B2B/job/Assets/job/B2B%20Asset%20Deployment%20Pipeline/job/master/) and click "Build Now"
4. When prompted, approve the execution of the Terraform plan.

### Verification

Once the Terraform plan has been applied:

1. Observe that the generated idempotent pipeline has been committed back to the [repository](http://bitbucket.high5.local/projects/BBIN/repos/b2b-asset-pipeline-demo/browse)
2. Observe that the following return version 2.0, as expected:
- `curl -k https://nj-nyx.qa.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.int-test.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.stage.h5grgs.co/gg/VERSION.txt`
- `curl -k https://nj-nyx.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.qa.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.int-test.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.stage.h5grgs.co/gg/VERSION.txt`
- `curl -k https:/gib-pp.h5grgs.co/gg/VERSION.txt`
3. Observe that the following still return version 1.0, as expected:
- `curl -k https://nj-nyx.qa.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.int-test.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.stage.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://nj-nyx.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.qa.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.int-test.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.stage.h5grgs.co/sotf/VERSION.txt`
- `curl -k https://gib-pp.h5grgs.co/sotf/VERSION.txt`
4. Observe that the `TODO` GCS bucket no longer exists by running `TODO`.
5. Observe that the `TODO` GCS bucket is set to `COLDLINE` by running `TODO`.
6. Observe that the contents of the `TODO` GCS bucket are set to `COLDLINE` by running `TODO`.

## Deploying New Integration Assets

We wish to deploy version 2.0 of the NYX NJ integration assets across all of `QA`, `int-test`, `stage` and `prod`. Since version 1.0 will no longer be necessary, version 1.0 will be obviated, and we can confirm that it is retired as expected.

### Migrating

The migration to perform this operation is defined in `./migration_templates/04.yaml`. To run this deployment:

1. Activate the migration: `cp migration_templates/04.yaml ./migrations/04.yaml`
2. Commit the migration so Jenkins picks up on it: `git add ./migrations/04.yaml && git commit -m "Demonstration phase 4" && git push origin head`
3. Navigate to the [Jenkins job](https://gcp-jenkins.high5games.com/job/B2B/job/Assets/job/B2B%20Asset%20Deployment%20Pipeline/job/master/) and click "Build Now"
4. When prompted, approve the execution of the Terraform plan.

### Verification

Once the Terraform plan has been applied:

1. Observe that the generated idempotent pipeline has been committed back to the [repository](http://bitbucket.high5.local/projects/BBIN/repos/b2b-asset-pipeline-demo/browse)
2. Observe that the following return version 2.0, as expected:
- `curl -k https://nj-nyx.qa.h5grgs.co/VERSION.txt`
- `curl -k https://nj-nyx.int-test.h5grgs.co/VERSION.txt`
- `curl -k https://nj-nyx.stage.h5grgs.co/VERSION.txt`
- `curl -k https://nj-nyx.h5grgs.co/VERSION.txt`
3. Observe that the `TODO` GCS bucket no longer exists by running `TODO`.
4. Observe that the `TODO` GCS bucket is set to `COLDLINE` by running `TODO`.
5. Observe that the contents of the `TODO` GCS bucket are set to `COLDLINE` by running `TODO`.

## Integration Configuration Assets

As part of the integration asset deployment process, a GCS bucket is created for storing a `config.json` file, accessible at the path `/config/config.json`. Keys with access to this bucket are generated and stored in a centralized bucket, for use by H5G's internal tooling.

### Verification

1. Fetch the generated key for ...: `TODO`
2. Use the generated key to upload a sample `config.json`: `echo "{ \"foo\": \"bar\" }" > /tmp/config.json && TODO`
3. Confirm that the following return the sample `config.json`:
- `curl -k https://nj-nyx.qa.h5grgs.co/config/config.json`
- `curl -k https://nj-nyx.int-test.h5grgs.co/config/config.json`
- `curl -k https://nj-nyx.stage.h5grgs.co/config/config.json`
- `curl -k https://nj-nyx.h5grgs.co/config/config.json`

## Cleaning Up

A simple [cleanup script](./hack/cleanup.sh) is provided to reset the demonstration. Run `./hack/cleanup.sh` and commit the `pipelines/` and `migrations/` directories to Git to reset state to the beginning of this demonstration.
