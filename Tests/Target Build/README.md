Introduction
============
This folder contains the scripts needed to build a valid test target for
the tests in this framework. The metadata directory is meant to go on a
DHCP/web server and load balancer which handles building a CloudGuard
image using cloud-init. This allows the test target to be built
consistently. It doesn't require a permanent license. By making the
deployment reproducible like this, the test target can be rebuilt
frequently, so any changes made only last until you rebuild it.

The Services VM
---------------
Here is the network topology of the test target:

            +---------+
            | Clients |
            +---------+
                 |
          +-------------+
          | Services VM |
          +-------------+
           /     |     \
    +-----+   +-----+   +-----+
    | VM1 |   | VM2 |   | VM3 |
    +-----+   +-----+   +-----+

It consists of a services VM with a private network behind it. In this
private network, we create a series of instances of a CloudGuard image.
The services VM fills three major roles:

1. It provides DHCP for the CloudGuard machine
2. It is the metadata service for cloud-init. If you have another
metadata service (e.g, if you are running OpenStack), this role can be
skipped.
3. It runs a load balancer service which presents a consistent
certificate to clients which connect. This way, we are less tempted to
make clients skip certificate validation entirely.

I personally use [OpenBSD](https://www.openbsd.org) to fill this role.
It's small, and it includes all the features I need out of the box with
no additional package management needed.

Building the OpenBSD Services VM
--------------------------------
Make a VM with these settings:

- BIOS boot ROM
- 1 core
- 256 GB of RAM
- 20 GB hard drive
- two network interfaces

The drive can be sparse-provisioned. Once set up, it doesn't write much.
Here are the installation answers I use:

```
Install
Choose your keyboard layout = default (default)
System Hostname = $metadataVmName.replace(" ","-")
Network interface to configure = hvn0 (default)
IPv4 address for hvn0 = autoconf (default)
IPv6 address for hvn0 = autoconf
Network interface to configure = done (default)
Password for root account = 1qaz!QAZ
Start sshd(8) by default = yes (default)
Do you expect to run the X Window System = no
Change the default console to com0 = no (default)
Setup a user = no (default)
Allow root ssh login = yes
What timezone are you in = UTC
Which disk is the root disk = sd0 (default)
Encrypt the root disk with a passphrase = no (default)
Use (W)hole disk MBR, whole disk (G)PT, or (E)dit = whole (default)
Use (A)uto layout, (E)dit layout, or create (C)ustom layout = c
a a
offset = 64 (default)
size = 41110240
FW type = 4.2BSD (default)
mount point = /
a b
offset = 41110304 (default)
size = 832736 (default)
FW type = swap (default)
w
q
Location of sets = cd0 (default)
Pathname to the sets = 7.4/amd64 (default)
Set name(s) = -g*
Set name(s) = -x*
Set name(s) = done
Directory does not contain SHA256.sig. Continue without verification = yes
Location of sets = done (default)
Time appears wrong = yes (default)
Exit to (S)hell, (H)alt or (R)eboot = reboot (default)
```

Once the VM exists, we need to build configuration files for some
services:

- Contents of /etc/dhcpd.conf
```
subnet 169.254.0.0 netmask 255.255.0.0 {
	option routers 169.254.169.254;
	range 169.254.0.1 169.254.0.3;
	default-lease-time 1800;
	max-lease-time 1800;
}
```

- Contents of /etc/hostname.hvn0
```
inet autoconf
inet6 autoconf
```

- Contents of /etc/hostname.hvn1
```
inet 169.254.169.254 255.255.0.0
inet6 fe80::a9fe:a9fe 64
```

- Contents of /etc/httpd.conf
```
server "metadata.standingsmartcenter.mylab.local" {
	listen on * port 80
	root "/htdocs/metadata"
	directory index index.txt
	location "/jumbo/" {
		request rewrite "/jumbo/index.cgi"
	}
	location "/jumbo/index.cgi" {
		fastcgi
	}
}
```

- Contents of /etc/pf.conf
```
set skip on lo
block return log
block in quick from any to {224.0.0.251 ff02::fb}
pass in quick on hvn1 proto udp from port bootpc to port bootps
pass out quick on hvn1 proto udp from port bootps to port bootpc
pass out on hvn0 from hvn0
pass out on hvn1 from hvn1
pass in on hvn1 from hvn1:network to any
pass out on hvn0 from hvn1:network to any nat-to hvn0
anchor "relayd/*"
pass in on hvn0 proto tcp from any to hvn0 port {ssh www https}
block return out log proto {tcp udp} user _pbuild
```

- Contents of /etc/relayd.conf
```
table <insideServers> {169.254.0.1 169.254.0.2 169.254.0.3}
http protocol selfSignedCert {
	tls keypair "selfSigned"
}
relay "mgmtApi" {
	listen on hvn0 port https tls
	protocol selfSignedCert
	forward with tls to <insideServers> port https check https "/web_api/" code 401
}
```

- Contents of /root/.ssh/config
```
Host 169.254.0.?
	StrictHostKeyChecking no
	UserKnownHostsFile /dev/null
	User admin
```

Next, we enable the services. We also create a certificate for relayd to
use.

```
rcctl enable dhcpd httpd relayd slowcgi
rcctl set dhcpd flags hvn1
ln $(which ksh) /var/www/bin/ksh
ln $(which ls) /var/www/bin/ls
mkdir -p /var/www/htdocs/metadata/openstack/2015-10-15
mkdir /var/www/htdocs/metadata/jumbo
echo 'net.inet.ip.forwarding=1' >> /etc/sysctl.conf
echo 'net.inet6.ip6.forwarding=1' >> /etc/sysctl.conf
openssl req -x509 -days 365 -newkey rsa:2048 -passout pass:'1qaz2wsx' \
-subj "$(printf "/CN=metadata.standingsmartcenter.mylab.test"
printf "/C=ZZ/ST=Empty/L=Nowhereville"
printf "/O=My Lab/OU=Standing SmartCenter")" \
-keyout /etc/ssl/private/encrypted.key -out /etc/ssl/selfSigned.crt
openssl rsa -in /etc/ssl/private/encrypted.key -passin pass:'1qaz2wsx' \
-passout pass: -out /etc/ssl/private/selfSigned.key
```

Put the 'metadata' directory from here into `/var/www/htdocs` and run
these commands to set permissions, fetch the latest OS patches, then
reboot to let all the services come up:
```
chown -R www:www /var/www/htdocs/metadata
chmod 544 /var/www/htdocs/metadata/jumbo/index.cgi
chmod 644 /var/www/htdocs/metadata/openstack/2015-10-15/index.txt
chmod 644 /var/www/htdocs/metadata/openstack/2015-10-15/user_data
syspatch
reboot
```

Maintaining the Services VM
---------------------------
The `syspatch` command mentioned above fetches the latest patches and
installs them. You should run this periodically to keep the services VM
updated. About every six months, the OpenBSD team releases a new major
version. The upgrade process is only a little more involved. Run these
commands to upgrade to the latest major version:

```
sysupgrade -n
rm /home/_sysupgrade/g*
rm /home/_sysupgrade/x*
reboot
```

Updating the Deployment Agent and Providing a Jumbo
---------------------------------------------------
There is rarely a reason to run a Check Point management with no jumbo.
The services VM has a few scripts which handle downloading a CPUSE
installer from the services VM and installing it, then downloading a
jumbo from the services VM and installing it. Just put the deployment
agent file and the jumbo you want to install in
`/var/www/htdocs/metadata/jumbo`.

Functional VMs
--------------
Now that we have the services VM built, we need to create a functional
VM to actually run the Check Point management API so we can run our
tests. I use these settings:

- For a Security Management Server (formerly SmartCenter):
  - BIOS boot ROM
  - 2 cores
  - 16 GB of RAM
- For an MDS:
  - BIOS boot ROM
  - 4 cores - config_system will fail with fewer
  - 24 GB of RAM

Set the VM's network interface to the private network behind the
services VM. When it boots, it should make a DHCP request, then HTTP GET
to `169.254.169.254/openstack/2015-10-15`. The date is hard-coded into
Check Point's cloud-init. You can find access logs for the metadata
service in `/var/www/logs/access.log` on the services VM.
