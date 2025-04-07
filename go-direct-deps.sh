#! /bin/bash

go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all
