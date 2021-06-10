---
layout: post
title:  "Pwning Home Router - Linksys WRT54G"
date:   2021-05-30
categories: exploitation
---


# Preface
A couple of days ago,
I was looking for a certain cable in one of my drawers where suddenly I stumbled upon a router that was laying around.
Immediately I wondered..._Could I hack it?_  

![Router Image]
<p style="text-align: center; font-style: italic"><small>"Easy setup" - Perhaps. "Secure"? Not so much.</small></p>

It worked well for me because I was just looking for a new project to pick up on,
and I had no prior experience in tinkering with such devices and I thought it could be an interesting challenge.

# Getting Started
I connected the router to my computer and right away jumped onto the research.
I started off with a good ol' port scan in order to get a good grasp of the router's interfaces and my potential attack vectors.


```sh
➜  ~ nmap -F 192.169.1.1
Starting Nmap 7.91 ( https://nmap.org ) at 2021-06-07 21:43 IDT
Nmap scan report for 192.169.1.1
Host is up (0.0023s latency).
Not shown: 99 filtered ports
PORT   STATE SERVICE
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 18.20 seconds
```
Unsurprisingly, looks like all we got to work with is the web server. Off we go then.

Browsing to the router's website presents a login prompt,
to which I authenticate with the default credentials,
and shortly afterwards I'm introduced to the following control and management page.

![Web Interface]
<p style="text-align: center; font-style: italic"><small>The router's web interface.</small></p>

# Hacking Time

Initially, I searched for potential inputs from the client when I came across the Diagnostics page.
![Diagnostics Page]

I thought it could be a good place to apply the oldest blackbox technique in the book - _Shell Injection_.
Unfortunately, client-side validation was applied.
<center><video style="width: 480px; height: 495px; margin: 1rem" autoplay loop><source src="https://i.imgur.com/iM8isa8.mp4"></video></center>

In order to overcome it, I intercepted the request using a proxy.
<center><video style="width: 750px; height: 500px; margin: 1rem" autoplay loop><source src="https://i.imgur.com/36pK23Z.mp4"></video></center>

Sadly, it seemed to have no effect at all on the ping request.  
Needless to say that I also attempted the same on the Traceroute Test interface and many other places but without any luck.

# Getting The Firmware
At this point I was done with doing Blackbox attack variations, mostly because I had no reason to.  
I decided to download [the firmware], extract the file system, and begin messing around with what's available on the router.

```sh
➜  linksys-wrt54g binwalk -e FW_WRT54Gv4_4.21.5.000_20120220.bin 

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             BIN-Header, board ID: W54G, hardware version: 4702, firmware version: 4.21.21, build date: 2012-02-08
32            0x20            TRX firmware header, little endian, image size: 3362816 bytes, CRC32: 0xE3ABE901, flags: 0x0, version: 1, header size: 28 bytes, loader offset: 0x1C, linux kernel offset: 0xAB0D4, rootfs offset: 0x0
60            0x3C            gzip compressed data, maximum compression, has original file name: "piggy", from Unix, last modified: 2012-02-08 03:40:02
700660        0xAB0F4         Squashfs filesystem, little endian, version 2.0, size: 2654572 bytes, 502 inodes, blocksize: 65536 bytes, created: 2012-02-08 03:43:28

➜  linksys-wrt54g ls _FW_WRT54Gv4_4.21.5.000_20120220.bin.extracted/squashfs-root 
bin  dev  etc  lib  mnt  proc sbin tmp  usr  var  www
```

Intuitively, I started auditing the source code of the web application, because that's what I could access directly as an attacker.
```sh
➜  squashfs-root ls www
Backup_Restore.asp    Fail.asp              Forward.asp           PortTriggerTable.asp  SingleForward.asp     Success_u_s.asp       WEP.asp               WanMAC.asp            dyndns.asp            image                 it_help               tzo.asp
Cysaja.asp            Fail_s.asp            Forward.asp.bk.asp    Port_Services.asp     Status_Lan.asp        SysInfo.htm           WL_ActiveTable.asp    Wireless_Advanced.asp en_help               index.asp             it_lang_pack          wlaninfo.htm
DDNS.asp              Fail_u_s.asp          Log.asp               QoS.asp               Status_Router.asp     SysInfo1.htm          WL_FilterTable.asp    Wireless_Basic.asp    en_lang_pack          index_heartbeat.asp   sp_help
DHCPTable.asp         FilterIPMAC.asp       Log_incoming.asp      Radius.asp            Status_Router1.asp    Traceroute.asp        WL_WPATable.asp       Wireless_MAC.asp      fr_help               index_l2tp.asp        sp_lang_pack
DMZ.asp               FilterSummary.asp     Log_outgoing.asp      RouteTable.asp        Status_Wireless.asp   Triggering.asp        WPA.asp               common.js             fr_lang_pack          index_pppoe.asp       style.css
Diagnostics.asp       Filters.asp           Management.asp        Routing.asp           Success.asp           Upgrade.asp           WPA_Preshared.asp     de_help               google_redirect1.asp  index_pptp.asp        sw_help
Factory_Defaults.asp  Firewall.asp          Ping.asp              SES_Status.asp        Success_s.asp         VPN.asp               WPA_Radius.asp        de_lang_pack          google_redirect2.asp  index_static.asp      sw_lang_pack
```
Basically the web application is a bunch of `.asp` pages served through the `httpd` that is running.  

First thing I did was inspect `Ping.asp` in order to see how the ping invocation is done since I wanted to know what failed my shell injection.
It took me a few minutes to realize that the web application isn't the one that is doing the ping itself as I imagined it would with something like `Process.Start("ping ...");`,
but rather what actually happens is that it passes on the request to the `httpd` which handles it on its own.

Apparently, it's a common pattern in "small devices" to combine the web server with the application and business logic,
a theme with which I was not familiar.

Generally, the sole job of the web application is to pass parameters to the `httpd` which actually does the heavy lifting.
At this point I realized that sooner or later I'd have to reverse the HTTP daemon that is running on the router in order to see how it handles the requests.



[Router Image]: https://i.imgur.com/sAmlLfJ.jpg
[Web Interface]: https://i.imgur.com/QJj9iOA.png
[Diagnostics Page]: https://i.imgur.com/QctdaYi.png
[the firmware]: https://www.linksys.com/us/support-article?articleNum=148648
