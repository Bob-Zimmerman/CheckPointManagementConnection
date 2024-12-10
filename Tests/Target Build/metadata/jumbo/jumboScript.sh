#!/usr/bin/env bash
# Wait for the management API to be up and running.
false;while [ $? -ne 0 ];do
sleep 60
mgmt_cli -r true show hosts limit 1
done

fileNames=$(curl_cli http://169.254.169.254/jumbo/ | egrep "(DeploymentAgent|$(fw ver | cut -d' ' -f7 | tr '.' '_'))")
for fileName in $fileNames;do
curl_cli "http://169.254.169.254/jumbo/${fileName}" -o "/var/log/${fileName}"
if [[ "$fileName" == DeploymentAgent* ]];then
clish -c "lock database override"
clish -c "installer agent install /var/log/${fileName}"
rm "/var/log/${fileName}"
elif [[ "$fileName" == *_JUMBO_* ]];then
clish -c "lock database override"
clish -c "installer import local /var/log/${fileName}"
rm "/var/log/${fileName}"
echo "y" | clish -c "installer install ${fileName}"
fi
done
shutdown -r now
