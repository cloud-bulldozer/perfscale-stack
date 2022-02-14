#!/bin/bash

GIT_ROOT=$(git rev-parse --show-toplevel)

source $GIT_ROOT/scripts/common.sh

output_cluster_info

