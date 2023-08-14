#! /bin/bash -x

tag="${1:-2.1.6}"

# az acr repository show-tags -n secopscommondevacr --repository eplan/apim-template-generator

# docker run -ti --rm -u $UID -v $(pwd):/src secopscommondevacr.azurecr.io/eplan/apim-template-generator:${tag} version
docker run -ti --rm -u $UID -v $(pwd):/src secopscommondevacr.azurecr.io/eplan/apim-template-generator:${tag} generate -c /src/apim-generator-config.json
