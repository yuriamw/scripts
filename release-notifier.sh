#! /bin/bash

echo "golang toolchain"
curl -fsSL 'https://go.dev/dl/?mode=json&include=all' \
  | jq -r --arg repo 'golang/go' '.[0:5] | .[] | [$repo, .version, (if .stable then "stable" else "prerelease" end)] | @tsv'
echo

echo "prom/prometheus"
curl -fsSL 'https://hub.docker.com/v2/repositories/prom/prometheus/tags?page_size=15&ordering=last_updated' \
  | jq -r --arg repo 'prom/prometheus' '.results[] | [.last_updated, $repo, .name] | @tsv'
echo

echo "golangci/golangci-lint (releases)"
curl -fsSL 'https://api.github.com/repos/golangci/golangci-lint/releases?per_page=5' \
  | jq -r --arg repo 'golangci/golangci-lint' '.[] | [.published_at, $repo, .tag_name] | @tsv'
echo

echo "authzed/spicedb (releases)"
curl -fsSL 'https://api.github.com/repos/authzed/spicedb/releases?per_page=5' \
  | jq -r --arg repo 'authzed/spicedb' '.[] | [.published_at, $repo, .tag_name] | @tsv'
echo
