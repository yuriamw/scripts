#! /bin/bash

kubectl -n cs23 get deployments.apps,ingress,services,configmaps -o name
