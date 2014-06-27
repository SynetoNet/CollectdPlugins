#!/usr/bin/bash
ROOT=$(readlink -f `dirname $0`)
/usr/bin/sudo ${ROOT}/fc_iostat.d $COLLECTD_HOSTNAME