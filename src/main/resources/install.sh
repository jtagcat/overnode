#!/bin/bash

#
# Generated by Webintrinsics Clusterlite:
# __COMMAND__
#
# Parameters: __PARSED_ARGUMENTS__
# Environment: __ENVIRONMENT__
# Prerequisites:
# - Docker engine
# - Internet connection
#

set -e

install() {
    echo "__LOG__ downloading weave script"
    docker_location="$(which docker)"
    weave_destination="${docker_location/docker/weave}"
    docker run --rm -i clusterlite/weave:1.9.7 > ${weave_destination}
    chmod u+x ${weave_destination}

    echo "__LOG__ installing weave network"
    export CHECKPOINT_DISABLE=1 # disabling weave check for new versions
    # launching weave node for uniform dynamic cluster with encryption is enabled
    # see https://www.weave.works/docs/net/latest/operational-guide/uniform-dynamic-cluster/
    # automated range allocation does not require seeds to reach a consensus
    # because the range is split in advance by seeds enumeration
    # see https://github.com/weaveworks/weave/blob/master/site/ipam.md#via-seed
    weave launch --password __TOKEN__ \
        --dns-domain="clusterlite.local." \
        --ipalloc-range 10.32.0.128/25 --ipalloc-default-subnet 10.32.0.0/12 \
        __WEAVE_SEED_NAME__ --ipalloc-init seed=__WEAVE_ALL_SEEDS__ __SEEDS__

    echo "__LOG__ installing data directory"
    # creating reference to volume directory
    mkdir /var/lib/clusterlite || echo ""
    echo __VOLUME__ > /var/lib/clusterlite/volume.txt
    mkdir __VOLUME__ || echo ""
    mkdir __VOLUME__/clusterlite || echo ""
__ETCD_LAUNCH_PART__
    echo "__LOG__ saving configuration files"
    echo __CONFIG__ > __VOLUME__/clusterlite.json

    echo "__LOG__ done"
}
install
