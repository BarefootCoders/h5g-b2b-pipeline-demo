#!/bin/bash

function build_and_upload() {
  _type="$1"
  _name="$2"
  _version="$3"
  _artifact_id="$4"

  zip -r demo-assets/com.google.h5g.demo/${_type}/${_name}/${_version}.jar demo-assets/com.google.h5g.demo/${_type}/${_name}/${_version}/*

  mvn deploy:deploy-file -DgroupId=com.google.h5g.demo -DrepositoryId=h5g-demo -Dversion=${_version} -DgeneratePom=false -Dpackaging=jar -DartifactId=${_artifact_id} -Durl=http://35.193.73.84/repository/berlinsky-h5g-demo -Dfile=./demo-assets/com.google.h5g.demo/${_type}/${_name}/${_version}.jar
}

build_and_upload "game-assets" "golden-goddess" "1.0" "gg"
build_and_upload "game-assets" "golden-goddess" "2.0" "gg"
build_and_upload "game-assets" "secrets-of-the-forest" "1.0" "sotf"
build_and_upload "integration-assets" "nyx-nj" "1.0" "nyx-nj-int"
build_and_upload "integration-assets" "nyx-nj" "2.0" "nyx-nj-int"
build_and_upload "integration-assets" "pp-gib" "1.0" "pp-gib-int"
