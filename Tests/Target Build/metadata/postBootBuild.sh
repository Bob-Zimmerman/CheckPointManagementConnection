#!/usr/bin/bash -l
#
# This script builds a standard set of objects on a Check Point Security
# Management Server (formerly SmartCenter). The tests of this API client
# framework run against this configuration. It also has a lot of extra data for
# use in application-level tests (e.g, there are host objects to let you make
# sure your code is able to fetch existing host objects if needed).
#
# Framework tests may only depend on data added to a management in this script.
#
# Once on the management, the script expects to be either copied or linked to
# /etc/rc.d/rc3.d/S99zzzPostBootBuild, which will run it after the first reboot.

sessionName="Initial Build"
sessionDescription="Building an initial config to test a Check Point API client."

publishEvery=80
changeCount=1
publishBatch=1
apiPort=$(api status | grep 'APACHE Gaia Port' | awk '{print $NF}')
sessionCookie=$(mktemp)

function mgmtCmd {
	commandToRun=""
	for element in "${@}"; do
		if [[ "$element" =~ \  ]]; then
			commandToRun="${commandToRun} \"${element}\""
		else
			commandToRun="${commandToRun} ${element}"
		fi
	done
	echo "${commandToRun}" | xargs mgmt_cli --port "${apiPort}" -s "${sessionCookie}"
	if [ $? -eq 0 ]; then
		echo "Success ${publishBatch}.${changeCount}"
		((changeCount+=1))
	else
		echo "Failed: ${commandToRun}"
	fi
	if [ ${changeCount} -gt ${publishEvery} ]; then
		echo "Publishing..."
		publish
		setupSession
		changeCount=1
		((publishBatch+=1))
	fi
}

function publish {
	mgmt_cli --port "${apiPort}" -s "${sessionCookie}" publish
}

function setupSession {
	mgmt_cli --port "${apiPort}" -s "${sessionCookie}" set session new-name "${sessionName}" description "${sessionDescription}" > /dev/null
}

function login {
	mgmt_cli --port "${apiPort}" -d "${1}" -r true login > "${sessionCookie}"
	setupSession
}

function logout {
	publish
	mgmt_cli --port "${apiPort}" -s "${sessionCookie}" logout > /dev/null
	rm "${sessionCookie}"
}

# Wait for the management API to be up and running.
false;while [ $? -ne 0 ];do
sleep 60
mgmt_cli --port "${apiPort}" -r true show hosts limit 1
done

managementName=$(mgmt_cli --port "${apiPort}" -f json -r true show gateways-and-servers | jq '.objects[]|.name' | head -n 1 | tr -d '"')

login
mgmtCmd add simple-cluster name HoustonFW ipv4-address "10.74.255.1" anti-bot true anti-virus true application-control true content-awareness true firewall true ips true \
cluster-mode cluster-xl-ha \
interfaces.1.name eth0 \
interfaces.1.ipv4-address 10.74.255.1 \
interfaces.1.ipv4-mask-length 24 \
interfaces.1.interface-type cluster \
interfaces.1.topology external \
interfaces.1.anti-spoofing-settings.action prevent \
interfaces.2.name eth1.1 \
interfaces.2.ipv4-address 10.74.0.1 \
interfaces.2.ipv4-mask-length 23 \
interfaces.2.interface-type cluster \
interfaces.2.topology internal \
interfaces.2.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.2.anti-spoofing-settings.action prevent \
interfaces.3.name eth1.2 \
interfaces.3.ipv4-address 10.74.4.1 \
interfaces.3.ipv4-mask-length 23 \
interfaces.3.interface-type cluster \
interfaces.3.topology internal \
interfaces.3.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.3.anti-spoofing-settings.action prevent \
interfaces.4.name eth1.5 \
interfaces.4.ipv4-address 10.74.8.1 \
interfaces.4.ipv4-mask-length 23 \
interfaces.4.interface-type cluster \
interfaces.4.topology internal \
interfaces.4.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.4.anti-spoofing-settings.action prevent \
interfaces.5.name eth2 \
interfaces.5.interface-type sync \
members.1.name HoustonFW0 \
members.1.ipv4-address "10.74.255.2" \
members.1.interfaces.1.name eth0 \
members.1.interfaces.1.ipv4-address 10.74.255.2 \
members.1.interfaces.1.ipv4-mask-length 24 \
members.1.interfaces.2.name eth1.1 \
members.1.interfaces.2.ipv4-address 10.74.253.1 \
members.1.interfaces.2.ipv4-mask-length 30 \
members.1.interfaces.3.name eth1.2 \
members.1.interfaces.3.ipv4-address 10.74.253.5 \
members.1.interfaces.3.ipv4-mask-length 30 \
members.1.interfaces.4.name eth1.5 \
members.1.interfaces.4.ipv4-address 10.74.253.9 \
members.1.interfaces.4.ipv4-mask-length 30 \
members.1.interfaces.5.name eth2 \
members.1.interfaces.5.ipv4-address 10.0.0.1 \
members.1.interfaces.5.ipv4-mask-length 30 \
members.2.name HoustonFW1 \
members.2.ipv4-address "10.74.255.3" \
members.2.interfaces.1.name eth0 \
members.2.interfaces.1.ipv4-address 10.74.255.3 \
members.2.interfaces.1.ipv4-mask-length 24 \
members.2.interfaces.2.name eth1.1 \
members.2.interfaces.2.ipv4-address 10.74.253.2 \
members.2.interfaces.2.ipv4-mask-length 30 \
members.2.interfaces.3.name eth1.2 \
members.2.interfaces.3.ipv4-address 10.74.253.6 \
members.2.interfaces.3.ipv4-mask-length 30 \
members.2.interfaces.4.name eth1.5 \
members.2.interfaces.4.ipv4-address 10.74.253.10 \
members.2.interfaces.4.ipv4-mask-length 30 \
members.2.interfaces.5.name eth2 \
members.2.interfaces.5.ipv4-address 10.0.0.2 \
members.2.interfaces.5.ipv4-mask-length 30

mgmtCmd add simple-gateway name BerlinFW ipv4-address "10.111.255.1" firewall true ips true \
firewall-settings.auto-calculate-connections-hash-table-size-and-memory-pool true \
firewall-settings.auto-maximum-limit-for-concurrent-connections true \
interfaces.1.name eth0 \
interfaces.1.ipv4-address 10.111.255.1 \
interfaces.1.ipv4-mask-length 24 \
interfaces.1.topology external \
interfaces.1.anti-spoofing-settings.action prevent \
interfaces.2.name eth1.1 \
interfaces.2.ipv4-address 10.111.0.1 \
interfaces.2.ipv4-mask-length 23 \
interfaces.2.topology internal \
interfaces.2.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.2.anti-spoofing-settings.action prevent \
interfaces.3.name eth1.2 \
interfaces.3.ipv4-address 10.111.4.1 \
interfaces.3.ipv4-mask-length 23 \
interfaces.3.topology internal \
interfaces.3.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.3.anti-spoofing-settings.action prevent \
interfaces.4.name eth1.5 \
interfaces.4.ipv4-address 10.111.8.1 \
interfaces.4.ipv4-mask-length 23 \
interfaces.4.topology internal \
interfaces.4.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" \
interfaces.4.anti-spoofing-settings.action prevent

mgmtCmd add dns-domain name ".github.com" is-sub-domain false
mgmtCmd add dns-domain name ".test.com" is-sub-domain false
mgmtCmd add dns-domain name ".time.apple.com" is-sub-domain false
mgmtCmd add dns-domain name ".time.windows.com" is-sub-domain false
mgmtCmd add dns-domain name ".updates.windows.com" is-sub-domain false
mgmtCmd add dns-domain name ".www.github.com" is-sub-domain false
mgmtCmd add network name "Experimental 240/4" subnet4 "240.0.0.0" mask-length4 4 broadcast allow color red
mgmtCmd add network name "Multicast 224/4" subnet4 "224.0.0.0" mask-length4 4 broadcast allow
mgmtCmd add network name "RFC 10/8" subnet4 "10.0.0.0" mask-length4 8 broadcast allow
mgmtCmd add network name "RFC 172.16/12" subnet4 "172.16.0.0" mask-length4 12 broadcast allow
mgmtCmd add network name "RFC 192.168/16" subnet4 "192.168.0.0" mask-length4 16 broadcast allow
mgmtCmd add group name "RFC 1918 Addresses" members.1 "RFC 10/8" members.2 "RFC 172.16/12" members.3 "RFC 192.168/16"
mgmtCmd add tag name "Tanav"
mgmtCmd add tag name "Sibra"
mgmtCmd add tag name "Stax"
mgmtCmd add tag name "Houston"
mgmtCmd add tag name "Berlin"
mgmtCmd add tag name "Development"
mgmtCmd add tag name "Production"
mgmtCmd add host name "tanavHoustonDevWebVip" ipv4-address "10.74.254.1" tags.1 "Tanav" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "tanavHoustonDevWeb" subnet4 "10.74.0.0" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "tanavHoustonDevApp" subnet4 "10.74.0.8" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "tanavHoustonDevDb" subnet4 "10.74.0.16" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Development"
mgmtCmd add host name "tanavHoustonProdWebVip" ipv4-address "10.74.254.2" tags.1 "Tanav" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "tanavHoustonProdWeb" subnet4 "10.74.1.0" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "tanavHoustonProdApp" subnet4 "10.74.1.8" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "tanavHoustonProdDb" subnet4 "10.74.1.16" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Houston" tags.3 "Production"
mgmtCmd add host name "tanavBerlinDevWebVip" ipv4-address "10.111.254.1" tags.1 "Tanav" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "tanavBerlinDevWeb" subnet4 "10.111.0.0" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "tanavBerlinDevApp" subnet4 "10.111.0.8" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "tanavBerlinDevDb" subnet4 "10.111.0.16" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add host name "tanavBerlinProdWebVip" ipv4-address "10.111.254.2" tags.1 "Tanav" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "tanavBerlinProdWeb" subnet4 "10.111.1.0" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "tanavBerlinProdApp" subnet4 "10.111.1.8" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "tanavBerlinProdDb" subnet4 "10.111.1.16" mask-length4 29 broadcast allow tags.1 "Tanav" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add host name "sibraHoustonDevWebVip" ipv4-address "10.74.254.5" tags.1 "Sibra" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "sibraHoustonDevWeb" subnet4 "10.74.4.0" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "sibraHoustonDevApp" subnet4 "10.74.4.8" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "sibraHoustonDevDb" subnet4 "10.74.4.16" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Development"
mgmtCmd add host name "sibraHoustonProdWebVip" ipv4-address "10.74.254.6" tags.1 "Sibra" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "sibraHoustonProdWeb" subnet4 "10.74.5.0" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "sibraHoustonProdApp" subnet4 "10.74.5.8" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "sibraHoustonProdDb" subnet4 "10.74.5.16" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Houston" tags.3 "Production"
mgmtCmd add host name "sibraBerlinDevWebVip" ipv4-address "10.111.254.5" tags.1 "Sibra" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "sibraBerlinDevWeb" subnet4 "10.111.4.0" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "sibraBerlinDevApp" subnet4 "10.111.4.8" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "sibraBerlinDevDb" subnet4 "10.111.4.16" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add host name "sibraBerlinProdWebVip" ipv4-address "10.111.254.6" tags.1 "Sibra" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "sibraBerlinProdWeb" subnet4 "10.111.5.0" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "sibraBerlinProdApp" subnet4 "10.111.5.8" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "sibraBerlinProdDb" subnet4 "10.111.5.16" mask-length4 29 broadcast allow tags.1 "Sibra" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add host name "staxHoustonDevWebVip" ipv4-address "10.74.254.9" tags.1 "Stax" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "staxHoustonDevWeb" subnet4 "10.74.8.0" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "staxHoustonDevApp" subnet4 "10.74.8.8" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Development"
mgmtCmd add network name "staxHoustonDevDb" subnet4 "10.74.8.16" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Development"
mgmtCmd add host name "staxHoustonProdWebVip" ipv4-address "10.74.254.10" tags.1 "Stax" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "staxHoustonProdWeb" subnet4 "10.74.9.0" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "staxHoustonProdApp" subnet4 "10.74.9.8" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Production"
mgmtCmd add network name "staxHoustonProdDb" subnet4 "10.74.9.16" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Houston" tags.3 "Production"
mgmtCmd add host name "staxBerlinDevWebVip" ipv4-address "10.111.254.9" tags.1 "Stax" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "staxBerlinDevWeb" subnet4 "10.111.8.0" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "staxBerlinDevApp" subnet4 "10.111.8.8" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add network name "staxBerlinDevDb" subnet4 "10.111.8.16" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Development"
mgmtCmd add host name "staxBerlinProdWebVip" ipv4-address "10.111.254.10" tags.1 "Stax" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "staxBerlinProdWeb" subnet4 "10.111.9.0" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "staxBerlinProdApp" subnet4 "10.111.9.8" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add network name "staxBerlinProdDb" subnet4 "10.111.9.16" mask-length4 29 broadcast allow tags.1 "Stax" tags.2 "Berlin" tags.3 "Production"
mgmtCmd add wildcard name "Houston Dev" ipv4-address "10.74.0.0" ipv4-mask-wildcard "0.0.64.255" tags.1 "Houston" tags.2 "Development"
mgmtCmd add wildcard name "Houston Prod" ipv4-address "10.74.1.0" ipv4-mask-wildcard "0.0.64.255" tags.1 "Houston" tags.2 "Production"
mgmtCmd add wildcard name "Berlin Dev" ipv4-address "10.111.0.0" ipv4-mask-wildcard "0.0.64.255" tags.1 "Berlin" tags.2 "Development"
mgmtCmd add wildcard name "Berlin Prod" ipv4-address "10.111.1.0" ipv4-mask-wildcard "0.0.64.255" tags.1 "Berlin" tags.2 "Production"
mgmtCmd add time-group name "Stock Times" members.1 "Every_Day" members.2 "Off_Work" members.3 "Weekend"

mgmtCmd add access-layer name "Shared Cleanup" add-default-rule false firewall true shared true
mgmtCmd add access-rule layer "Shared Cleanup" position "bottom" name "Don't log NetBIOS junk" service "NBT" action "Drop" track.type "None"
mgmtCmd add access-rule layer "Shared Cleanup" position "bottom" name "Allow ICMP from private" source "RFC 1918 Addresses" service "icmp-proto" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Shared Cleanup" position "bottom" name "Reject from private" source "RFC 1918 Addresses" action "Reject" track.type "Log"
mgmtCmd add access-rule layer "Shared Cleanup" position "bottom" name "Cleanup rule" action "Drop" track.type "Log"

mgmtCmd add package name "OnlyHouston" access true desktop-security true qos true qos-policy-type recommended threat-prevention true installation-targets "HoustonFW"
mgmtCmd add access-rule layer "OnlyHouston Network" position "top" name "More rules" service "http" action "Accept"
mgmtCmd delete access-rule layer "OnlyHouston Network" rule-number 2
mgmtCmd add access-section layer "OnlyHouston Network" position "bottom" name "Throw more rules"
mgmtCmd add access-rule layer "OnlyHouston Network" position.bottom "Throw more rules" name "More rules" service "ntp-udp" action "Accept"
mgmtCmd add access-rule layer "OnlyHouston Network" position.bottom "Throw more rules" name "More rules" service "https" action "Accept"
mgmtCmd add access-rule layer "OnlyHouston Network" position.bottom "Throw more rules" name "More rules" service "PostgreSQL" action "Accept"
mgmtCmd add access-section layer "OnlyHouston Network" position "bottom" name "OK, stop rules"
mgmtCmd add access-section layer "OnlyHouston Network" position "bottom" name "That's a 50 DKP minus!"
mgmtCmd add access-rule layer "OnlyHouston Network" position.bottom "That's a 50 DKP minus!" action "Apply Layer" inline-layer "Shared Cleanup"

mgmtCmd add access-layer name "Second Policy, Second Layer" add-default-rule false firewall true shared false
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Connery"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "Dr. No"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "From Russia with Love"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "Goldfinger"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "Thunderball"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "You Only Live Twice"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Connery" name "Diamonds are Forever"
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Lazenby"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Lazenby" name "On Her Majesty's Secret Service"
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Moore"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "Live and Let Die"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "The Man with the Golden Gun"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "The Spy who Loved Me"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "Moonraker"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "For Your Eyes Only"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "Octopussy"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Moore" name "A View to a Kill"
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Dalton"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Dalton" name "The Living Daylights"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Dalton" name "License to Kill"
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Brosnan"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Brosnan" name "GoldenEye"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Brosnan" name "Tomorrow Never Dies"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Brosnan" name "The World is Not Enough"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Brosnan" name "Die Another Day"
mgmtCmd add access-section layer "Second Policy, Second Layer" position "bottom" name "Craig"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Craig" name "Casino Royale"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Craig" name "Quantum of Solace"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Craig" name "Skyfall"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Craig" name "Spectre"
mgmtCmd add access-rule layer "Second Policy, Second Layer" position.bottom "Craig" name "No Time to Die"
mgmtCmd set package name "OnlyHouston" access-layers.add.1.name "Second Policy, Second Layer" access-layers.add.1.position 2

mgmtCmd add access-rule layer "Network" position "top" name "Sectionless" service "echo-request" action "Accept" track.type "None"
mgmtCmd delete access-rule layer "Network" rule-number 2
mgmtCmd add access-rule layer "Network" position "bottom" name "Management access" source "RFC 1918 Addresses" destination.1 "${managementName}" destination.2 BerlinFW destination.3 HoustonFW service.1 "ssh" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position "bottom" name "Bad browsing" enabled false source "RFC 1918 Addresses" destination "RFC 1918 Addresses" destination-negate true service.1 "Child Abuse" service.2 "Critical Risk" service.3 "Facebook" service.4 "Hate / Racism" service.5 "Illegal / Questionable" action "Drop" track.type "Log"
mgmtCmd add access-section layer "Network" position "bottom" name "Development Sites"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "Houston Dev" source.2 "Berlin Dev" destination.1 ".github.com" destination.2 ".www.github.com" service.1 "ssh" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source "RFC 1918 Addresses" source-negate true destination.1 "tanavHoustonDevWebVip" destination.2 "tanavBerlinDevWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "tanavHoustonDevWeb" source.2 "tanavBerlinDevWeb" destination.1 "tanavHoustonDevApp" destination.2 "tanavBerlinDevApp" service.1 "irc1" service.2 "irc2" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "tanavHoustonDevApp" source.2 "tanavBerlinDevApp" destination.1 "tanavHoustonDevDb" destination.2 "tanavBerlinDevDb" service "MS-SQL-Server" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source "RFC 1918 Addresses" source-negate true destination.1 "sibraHoustonDevWebVip" destination.2 "sibraBerlinDevWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "tanavHoustonDevWeb" source.2 "tanavBerlinDevWeb" destination.1 "sibraHoustonDevWebVip" destination.2 "sibraBerlinDevWebVip" service "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "sibraHoustonDevWeb" source.2 "sibraBerlinDevWeb" destination.1 "sibraHoustonDevApp" destination.2 "sibraBerlinDevApp" service.1 "irc1" service.2 "irc2" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "sibraHoustonDevApp" source.2 "sibraBerlinDevApp" destination.1 "sibraHoustonDevDb" destination.2 "sibraBerlinDevDb" service.1 "sqlnet2-1521" service.2 "sqlnet2-1525" service.3 "sqlnet2-1526" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source "RFC 1918 Addresses" source-negate true destination.1 "staxHoustonDevWebVip" destination.2 "staxBerlinDevWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "tanavHoustonDevWeb" source.2 "tanavBerlinDevWeb" source.3 "sibraHoustonDevWebVip" source.4 "sibraBerlinDevWebVip" destination.1 "staxHoustonDevWebVip" destination.2 "staxBerlinDevWebVip" service "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "staxHoustonDevWeb" source.2 "staxBerlinDevWeb" destination.1 "staxHoustonDevApp" destination.2 "staxBerlinDevApp" service.1 "exec" service.2 "login" service.3 "shell" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Development Sites" source.1 "staxHoustonDevApp" source.2 "staxBerlinDevApp" destination.1 "staxHoustonDevDb" destination.2 "staxBerlinDevDb" service "sqlnet1" action "Accept" track.type "None"
mgmtCmd add access-section layer "Network" position "bottom" name "Production Sites"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source "RFC 1918 Addresses" source-negate true destination.1 "tanavHoustonProdWebVip" destination.2 "tanavBerlinProdWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "tanavHoustonProdWeb" source.2 "tanavBerlinProdWeb" destination.1 "tanavHoustonProdApp" destination.2 "tanavBerlinProdApp" service.1 "irc1" service.2 "irc2" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "tanavHoustonProdApp" source.2 "tanavBerlinProdApp" destination.1 "tanavHoustonProdDb" destination.2 "tanavBerlinProdDb" service "MS-SQL-Server" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source "RFC 1918 Addresses" source-negate true destination.1 "sibraHoustonProdWebVip" destination.2 "sibraBerlinProdWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "tanavHoustonProdWeb" source.2 "tanavBerlinProdWeb" destination.1 "sibraHoustonProdWebVip" destination.2 "sibraBerlinProdWebVip" service "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "sibraHoustonProdWeb" source.2 "sibraBerlinProdWeb" destination.1 "sibraHoustonProdApp" destination.2 "sibraBerlinProdApp" service.1 "irc1" service.2 "irc2" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "sibraHoustonProdApp" source.2 "sibraBerlinProdApp" destination.1 "sibraHoustonProdDb" destination.2 "sibraBerlinProdDb" service.1 "sqlnet2-1521" service.2 "sqlnet2-1525" service.3 "sqlnet2-1526" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source "RFC 1918 Addresses" source-negate true destination.1 "staxHoustonProdWebVip" destination.2 "staxBerlinProdWebVip" service.1 "http" service.2 "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "tanavHoustonProdWeb" source.2 "tanavBerlinProdWeb" source.3 "sibraHoustonProdWebVip" source.4 "sibraBerlinProdWebVip" destination.1 "staxHoustonProdWebVip" destination.2 "staxBerlinProdWebVip" service "https" action "Accept" track.type "Log"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "staxHoustonProdWeb" source.2 "staxBerlinProdWeb" destination.1 "staxHoustonProdApp" destination.2 "staxBerlinProdApp" service.1 "exec" service.2 "login" service.3 "shell" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Production Sites" source.1 "staxHoustonProdApp" source.2 "staxBerlinProdApp" destination.1 "staxHoustonProdDb" destination.2 "staxBerlinProdDb" service "sqlnet1" action "Accept" track.type "None"
mgmtCmd add access-section layer "Network" position "bottom" name "Access to Public Services"
mgmtCmd add access-rule layer "Network" position.bottom "Access to Public Services" source "RFC 1918 Addresses" destination.1 ".time.apple.com" destination.2 ".time.windows.com" service "ntp-udp" action "Accept" track.type "None"
mgmtCmd add access-rule layer "Network" position.bottom "Access to Public Services" source "RFC 1918 Addresses" destination ".updates.windows.com" service.1 "http" service.2 "https" action "Accept" track.type "None"
mgmtCmd add access-section layer "Network" position "bottom" name "Cleanup"
mgmtCmd add access-rule layer "Network" position.bottom "Cleanup" action "Apply Layer" inline-layer "Shared Cleanup"
mgmtCmd add nat-rule package "Standard" position "top" original-source "RFC 10/8" original-destination "RFC 10/8"
mgmtCmd add nat-rule package "Standard" position.bottom "Manual Lower Rules" original-source "RFC 172.16/12" original-destination "RFC 172.16/12"
mgmtCmd add nat-rule package "Standard" position.bottom "Manual Lower Rules" original-source "RFC 192.168/16" original-destination "RFC 192.168/16"
mgmtCmd add nat-section package "Standard" position "bottom" name "More rules"
mgmtCmd add nat-rule package "Standard" position.bottom "More rules" original-source "RFC 10/8" original-destination "RFC 172.16/12" translated-source "HoustonFW" method "hide"
mgmtCmd add nat-rule package "Standard" position.bottom "More rules" original-source "RFC 10/8" original-destination "RFC 192.168/16" translated-source "HoustonFW" method "hide"
mgmtCmd add nat-rule package "Standard" position.bottom "More rules" original-source "RFC 172.16/12" original-destination "RFC 192.168/16" translated-source "HoustonFW" enabled false

mgmtCmd add package name "InstalledNowhere" access true
installedNowhereUuid=$(mgmt_cli --port "${apiPort}" -f json -s "${sessionCookie}" show package name "InstalledNowhere" details-level uid | jq '.uid')
mgmtCmd set generic-object uid "${installedNowhereUuid}" installationTargets "SPECIFIC_GATEWAYS"
mgmtCmd install-database targets "${managementName}"
logout

# Set up some users and set the API to allow connections from remote clients.
login "System Data"
mgmtCmd add administrator name "PasswordUser" authentication-method "check point password" password '1qaz!QAZ' must-change-password false permissions-profile "Super User"
mgmtCmd add domain-permissions-profile name "NoApiAccess" management.management-api-login false
mgmtCmd add administrator name "NoApi" authentication-method "check point password" password '1qaz!QAZ' must-change-password false permissions-profile "NoApiAccess"
mgmtCmd add administrator name "apiKeyUser" permissions-profile "Super User" authentication-method "api key"
mgmtCmd set api-settings accepted-api-calls-from "all ip addresses that can be used for gui clients"
logout
api throttling off
api restart

# Remove the script from the runlevel 3 pool so it only runs once.
rm /etc/rc.d/rc3.d/S99zzzPostBootBuild
