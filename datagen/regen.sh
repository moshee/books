#!/bin/bash

set -e
sudo -u postgres psql < ../model.sql
if [ -z "$1" ]; then
	ruby gen.rb | sudo -u postgres psql
else
	ruby gen.rb "$1" | sudo -u postgres psql
fi
