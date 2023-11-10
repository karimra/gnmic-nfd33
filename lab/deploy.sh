#!/bin/bash

set -e

labname=nfd33

sudo clab deploy -t $labname.clab.gotmpl -c
