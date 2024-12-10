#!/bin/ksh
echo "Content-type: application/octet-stream"
echo ""
cpuseName=""
for line in $(ls -1tr DeploymentAgent*);do
cpuseName="$line"
done
[ -n "$cpuseName" ] && echo "$cpuseName"
jumboName=""
for line in $(ls -1tr *_JUMBO_*);do
jumboName="$line"
done
[ -n "$cpuseName" ] && echo "$jumboName"
