#!/bin/bash

LONG="hack:,author:,title:"

OPTS=$(getopt -o '' --longoptions ${LONG} -- "$@")

eval set -- "${OPTS}"

while :; do
    case "${1}" in
        --hack        ) HACK="${2}"        ;;
        --author      ) AUTHOR="${2}"      ;;
	      --title       ) TITLE="${2}"       ;;
        --            ) shift; break       ;;
    esac
    shift
done

HACK=healthcare-cms-datalake
AUTHOR=kayjay@google.com
TITLE="Healthcare CMS Datalake"

BASEDIR="hacks/$HACK"


mkdir -p $BASEDIR
mkdir -p $BASEDIR/artifacts
mkdir -p $BASEDIR/resources
mkdir -p $BASEDIR/images

touch $BASEDIR/images/.gitkeep

cp faq/template-student-guide.md $BASEDIR/README.md
cp faq/template-coach-guide.md $BASEDIR/solutions.md
cp faq/template-lectures.pdf $BASEDIR/resources/

sed -i -e "s|^# \[TITLE\]|# ${TITLE}|" $BASEDIR/README.md
sed -i -e "s|^# \[TITLE\]|# ${TITLE}|" $BASEDIR/solutions.md

cat <<EOF > $BASEDIR/QL_OWNER
meken@google.com
# Collaborators
ginof@google.com
EOF

LICENSE=`cat tools/header.txt`

cat <<EOF > $BASEDIR/artifacts/outputs.tf
$LICENSE
output "project_id" {
    value = var.gcp_project_id
}
EOF

cat <<EOF > $BASEDIR/artifacts/providers.tf
$LICENSE
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}
EOF

cat <<EOF > $BASEDIR/artifacts/variables.tf
$LICENSE
variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to create resources in."
}

# Default value passed in
variable "gcp_region" {
  type        = string
  description = "Region to create resources in."
  default     = "us-central1"
}

# Default value passed in
variable "gcp_zone" {
  type        = string
  description = "Zone to create resources in."
  default     = "us-central1-c"
}
EOF

cat <<EOF > $BASEDIR/artifacts/main.tf
$LICENSE
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false  
}
EOF

cat <<EOF > $BASEDIR/artifacts/runtime.yaml
$LICENSE
runtime: terraform
version: 1.0.1
EOF

TAB="$(printf '\t')"
cat <<EOF > $BASEDIR/artifacts/Makefile
$LICENSE
TARGET=ghacks-setup.zip
OBJS=*.tf runtime.yaml

\$(TARGET): \$(OBJS)
${TAB}zip -r \$(TARGET) \$(OBJS)

clean:
${TAB}rm -f \$(TARGET)
EOF

cat <<EOF > $BASEDIR/resources/Makefile
$LICENSE
TARGET=student-files.zip
OBJS=*.*

\$(TARGET): \$(OBJS)
${TAB}zip -r \$(TARGET) \$(OBJS)

clean:
${TAB}rm -f \$(TARGET)
EOF

USERS=""
for i in {1..5}
do
    read -r -d '' NEWUSER <<EOF
  - type: gcp_user
    id: user_$i
    permissions:
    - project: project
      roles:
      - roles/owner
EOF
    printf -v USERS '%s  %s\n' "$USERS" "$NEWUSER"
done

OUTPUTS=""
for i in {1..5}
do
    read -r -d '' NEWOUTPUT <<EOF
  - label: Username $i
    reference: user_$i.username
  - label: Password $i
    reference: user_$i.password
EOF
    printf -v OUTPUTS '%s  %s\n' "$OUTPUTS" "$NEWOUTPUT"
done

cat <<EOF > $BASEDIR/qwiklabs.yaml
$LICENSE
schema_version: 2
default_locale: en
title: "[gHacks] $TITLE"
description: ""
instruction:
  type: md
  uri: instructions/en.md
duration: 480
max_duration: 600
credits: 0
level: fundamental
tags:
product_tags: 
role_tags:
domain_tags:
environment:
  resources:
  - type: gcp_project
    id: project
    startup_script:
      type: qwiklabs
      path: artifacts
$USERS
  student_visible_outputs:
  - label: Open Console
    reference: project.console_url
$OUTPUTS
  - label: Project ID
    reference: project.project_id
EOF

