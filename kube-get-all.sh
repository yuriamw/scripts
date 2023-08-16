#! /bin/bash

kubectl -n cs23 get -o custom-columns=:.metadata.name deploy,services,ingress,configmaps
