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
I also attempted the same thing on the Traceroute Test but interface without any luck.


[Router Image]: https://i.imgur.com/sAmlLfJ.jpg
[Web Interface]: https://i.imgur.com/QJj9iOA.png
[Diagnostics Page]: https://i.imgur.com/QctdaYi.png
