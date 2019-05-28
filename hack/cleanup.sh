#!/bin/bash

set -e
set -x

git pull --rebase origin head
docker run -v "$(pwd)"/migrations:/migrations -v "$(pwd)"/pipeline:/pipeline -v "$(pwd)"/hcl:/hcl gcr.io/berlinsky-h5g-demo-docker/h5g-b2b-pipeline-deployment-manager:cli --migration-dir=/migrations --pipeline-output-file=/pipeline/b2b-asset-pipeline.yaml --hcl-output-dir=/hcl
cd hcl
GOOGLE_APPLICATION_CREDENTIALS=../credentials/runner.json terraform destroy
rm -rf pipelines/*.yml pipelines/*.yaml migrations/*.yml migrations/*.yaml hcl/main.tf hcl/.terraform
