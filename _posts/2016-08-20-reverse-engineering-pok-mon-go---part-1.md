---
layout: post
title: "Reverse engineering Pokémon Go's API as a non-hacker - part 1"
description: A disheartening tale about a non-hacker who only wanted to reverse engineer the Pokémon Go API. How hard could it be?
headline: 
modified: 2016-08-20 01:51:55 -0300
category: personal
tags: [security, pokemon, reverse engineering, http, api]
imagefeature: 
mathjax: 
chart: 
comments: true
featured: false
---

Finally, after months of wait, I was able to install Pokémon Go in my Zenfone 2 with an Intel processor. As someone who grew up playing Pokémon, I must say the game didn't impress me so far. This is not a review, though. I have the luck of living close to a PokéStop in a square, so my style of play is basically keeping my phone sitting by my side the whole day, occasionally making pauses to get some Poké balls and capture a few Magikarps. I thought it would be cool to write a small application to show a desktop notification when there's a Pokémon close to me, so I could save some battery by turning off the game. How hard could it be?

Oh man, was I wrong.

I must warn you, before you keep reading, that this is not a tutorial. Neither it is a successful story. This is a *tale of sorrow and tears*, and a lot, a **lot** of googling. It's a compilation of some of the several resources I used and the report of how I got there. Bear with me while I stumble upon problem after problem in this long journey.

Naive as I am, I assumed that there would be a public API, as there's so many apps and services related to the game that I thought it was obvious that that was the case. So far, there's no such thing. There is, though, a lot of brave developers who reverse-engineered the API and released open source clients. And that's when my story really begins.

I was never what you would call a hacker. I get temporarily blind whenever I see an hexadecimal value (unless it's a CSS property's value, of course), Assembly bores me to death (more on that later), even C gives me a hard time, and even though I deeply admire those who take the time to deal with such things, I myself have always been a modest web developer. My Computer Science bachelor's degree doesn't serve me for anything. Basically, this whole stuff is *not* easy for me. That's why, once I realized this opportunity, I couldn't think of anything else: I **know** HTTP! Give me a request and I'll be able to comprehend and replicate it. Reverse-engineering a black-box API with the client sitting in my hand couldn't be so difficult, right?

If I was to read the requests, I'd need a way to intercept them as I do when debugging a website. First I tried the Android Monitor, which drove me crazy for an hour before I realized that only apps with a debug flag could be connected to it. Then I tried to install several sniffer apps, only to realize that the communication was through HTTPS (obviously), and therefore encrypted. And that's when I remembered about [Man-In-The-Middle attacks](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) from my Networking classes. Haha, just kidding, I read about it online which reminded me vaguely about the classes.

Here's a brief description of how a MitM attack works: a proxy is set up such that it intercepts the requests from the client, using a custom certificate that is installed manually in the device to decrypt them, then use another certificate to encode and forward the request to the original server, then decode the response, encode it again using its own certificate, and finally respond the client. Basically, the client thinks that it's communicating with the server, the server thinks that it's communicating with the client, and meanwhile the Man-In-The-Middle laughs and eat Doritos while reading all your sexting.

Before I go ahead, most of the following steps were based on the following articles: [Mitmproxy: Your D.I.Y. Private Eye](https://medium.com/@maxgreenwald/mitmproxy-your-d-i-y-private-eye-864c08f84736#.pzyl7u85k) and [How To: Use mitmproxy to read and modify HTTPS traffic](https://blog.heckel.xyz/2013/07/01/how-to-use-mitmproxy-to-read-and-modify-https-traffic-of-your-phone/).

The tool I chose was a Python lib called [mitmproxy](https://mitmproxy.org/). After setting it up, I needed to install its certificate into the device. For more information on how to get the file, check the [documentation](http://docs.mitmproxy.org/en/latest/certinstall.html). One thing that's important to note is that the mitmproxy lib doesn't provide a .crt file, which is required by Android, so I used this command to convert the .pem file I got: `openssl x509 -outform der -in mitmproxy-ca-cert.pem -out mitmproxy-ca-cert.crt` ([thanks, random guy in StackOverflow](http://stackoverflow.com/a/14484363/2908285)).

After booting up `mitmproxy`, I needed to configure the Wi-Fi connection in the device to use its address as a proxy. I had another problem there, and I'm sure that if I had paid more attention to my Networking classes I surely would have fixed this issue sooner: the device simply couldn't connect to the proxy. I tried many different combinations of proxy configuration and options to `mitmproxy`, with no success. That's when I realized that the device was connected to an adhoc network being broadcasted from my ethernet-connected laptop, which I had configured due to my router's low range, and therefore wouldn't be able to find the proxy's IP since they weren't in the same network. I'm sure that there are ways to make `mitmproxy` work ([Mitmproxy: Your D.I.Y. Private Eye](https://medium.com/@maxgreenwald/mitmproxy-your-d-i-y-private-eye-864c08f84736#.pzyl7u85k) mentions it with no details), but I was tired already.

I connected to the router's Wi-Fi and, like magic, it was working! The `mitmproxy` was printing every request made from the device, including the encrypted ones! The world was mine, mwahaha! Or so I thought.

Oh how I wish I had taken a screenshot as a proof of my glorious moment! After a pause for dinner I returned to work, determined to isolate each and every kind of request made from the Pokémon Go app, only to find that no request *coming from the app* was being intercepted anymore. Requests from the other apps were flying around unrestricted, but no signals of life from Pokémon Go. Hmm, that's odd.

If there was not even a failed request being registered, that means that it wasn't the server who discovered my machinations, but rather the app itself, who wasn't even trying to send anything anymore. After some research, I found out that [Certificate Pinning](https://en.wikipedia.org/wiki/HTTP_Public_Key_Pinning) is a thing, and it is even mentioned in the `mitmproxy`'s [docs](http://docs.mitmproxy.org/en/stable/certinstall.html#certificate-pinning), which I had read before (and here’s today’s lesson kids, pay attention to your documentations). Basically the application has stored a copy of the public key (or at least part of it) of the server it intends to communicate with, and therefore was able to identify my MitM as an attacker. It doesn't really matter that I was not trying to do anything malicious, it broke my attempt to even try to understand its API. I'm even afraid that they will ban my account for this, I should have anticipated it and used a fake one.

Here's where things get really complicated, and when I bailed -- at least for now. There *are* ways to work around the Certificate Pinning technique, but it involves using a disassembler and find, in that generated Assembly code, the code responsible for this protection, and modify it. It's not actually that hard, most of it is finding patterns and figuring out control flows, but even so, that's enough for an innocent attempt at reverse engineering an API. For those of you who are braver than me, [here's an excellent guide showing how to do this](https://eaton-works.com/2016/07/31/reverse-engineering-and-removing-pokemon-gos-certificate-pinning/). If you're not brave, but still want to go ahead and crack the APK, [here's a constantly updated project that does that](https://github.com/rastapasta/pokemon-go-xposed).

As for me, I'll let you with this incomplete and disappointing adventure. Join me the next time when I'll probably drink some alcohol and find the courage to face those disheartening hexadecimals and disassembled code!

By the way, if you want to read an article from someone who **really** knows what she's (or he's, apparently the name is French) doing, check out [Unbundling Pokémon Go](https://applidium.com/en/news/unbundling_pokemon_go/). It's worth mentioning that at the time of that article's writing, there was no Certificate Pinning in place yet.

See you next time!
