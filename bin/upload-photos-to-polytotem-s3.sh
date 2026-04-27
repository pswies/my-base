#!/bin/bash

for f in *; do
  echo $f
  tar cf $f.tar $f
  AWS_PROFILE=polytotem aws s3 cp $f.tar s3://pswies-priv-nowozytnosc/$f.tar
  rm $f.tar
done
