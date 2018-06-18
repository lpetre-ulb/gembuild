#!/bin/bash

## Script to extract versioning information from a git tag
# usage tag2rel.sh <tag>
# tag is (optionally) the tag being used to create a release in the form vX.Y.Z(-(alpha|beta|dev|pre|rc)[0-9]+)?(-git[a-fA-F0-9]{6,8})?
# * version is the vX.Y.Z string
# * relver is the release version for an RPM i.e., X.Y.Z-relver
# * gitrev is the git revision hash of the commit

if [ -z ${1+x} ]
then
    version=$(git describe --abbrev=0 --tags --always)
else
    version=$1
fi

relver=1
gitrev=$(git rev-parse --short HEAD)
gitver=$(git describe --abbrev=6 --dirty --always --tags)

# do some check on what this reports, and do/n't build a release depnding?
# git describe --dirty --always --tags
# v0.99.0-pre10-1-g1d2571a-dirty

# basic version unit is vX.Y.Z
vre='^v?(.)?([0-9]+).([0-9]+).([0-9]+)'

fullver=${version}

if [[ $version =~ $vre$ ]]
then
    basever=$version
elif [[ $version =~ $vre ]]
then
    if [[ "${version##*.}" =~ ^git ]]
    then
        version=${version%.*}
    elif [[ "${version##*-}" =~ ^git ]]
    then
        version=${version%-*}
    fi

    ## extras can appear in the tag as v.X.Y.Z((.|-)extra)+
    # need to force release to have only .
    if [[ "${version##*.}" =~ ^(alpha|beta|dev|pre|rc) ]]
    then
        basever=${version%.*}
        tags=( $(git tag -l "*${basever}*") )
        ntags=$((${#tags[@]}+1))
        relver=0.$ntags.${version##*.}
    elif [[ "${version##*-}" =~ ^(alpha|beta|dev|pre|rc) ]]
    then
        basever=${version%-*}
        tags=( $(git tag -l "*${basever}*") )
        ntags=$((${#tags[@]}+1))
        relver=0.$ntags.${version##*-}

        # Currently not safe about absolutely incrementing, i.e., want to enforce:
        #0.1.alpha0
        #0.2.alpha1
        #0.3.beta0
        #0.4.beta1
        #0.5.pre0
        #0.6.pre1
        #0.7.rc0
        #0.8.rc1
    fi
else
    basever=untagged
fi

if ! [[ ${basever} =~ "untagged" ]]
then
    version=${basever##v}
    patch=${version##*.}
    version=${version%.*}
    minor=${version##*.}
    major=${version%.*}
    version=${basever##v}
else
    version=${basever##v}
    fullver=${version}-${gitrev}git

fi

## Output a single parseable line? or output multiple lines?
echo Major:${major} \
     Minor:${minor} \
     Patch:${patch} \
     Release:$relver \
     Version:${version} \
     FullVersion:${fullver} \
     TagVersion:${basever} \
     Revision:${gitrev} \
     GitVersion:${gitver}
