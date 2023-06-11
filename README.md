**mspe** is an [MSP](https://github.com/CpanelInc/tech-MSP)-like tool for Postfix servers.

```
# mspe --rotated
Fetching mail server stats...

⏳ Queue Size: 10

✔️ Authenticated Senders:
      8 admin@example.com
      4 greg@example.com
      1 orders@example.com

🧔 User Senders:
     26 root
      1 n6505b5

📧 Top Email Subjects:
      8 Whole lotta test emails
      2 BUY MY GIANT PET LIZARD
      1 WHY ARE YOU NOT BUYING MY GIANT PET LIZARD???
      1 Someone bought something from Some Store
      1 HIS NAME IS ELLIOT
```
```
# mspe --rbl
Checking IPs in RBLs...

173.231.250.242:
        👍 b.barracudacentral.org
        👍 bl.spamcop.net
        👍 dnsbl.sorbs.net
        👍 zen.spamhaus.org
```

It recreates the most useful (IMO) features from MSP, like showing the full mail server stats and checking server IPs against RBLs. In the future I might add support to output important config values also.

## Email Subjects in the Postfix maillog

Postifx doesn't record the email subject by default in its log. You'll need to add an include in the config for this.

1. Uncomment or add this to the Postfix `main.cf` file:
```
header_checks = regexp:/etc/postfix/header_checks
```

2. Add this to the file:
```
/^Subject:/ WARN
```

3. And then save and reload Postfix. All new emails in the log will record the subject line now.

Unfortunately Postfix doesn't have a way (that I know of) to record the directory an email was sent out of (like Exim's `cwd`).

## FAQ

**Q:** There a minified version I can paste into the shell?

**A:** ~~I'll get to that after my nap.~~ It's done!

**Q:** Can I have this without the stupid emojis?

**A:**

![Never.](https://media.tenor.com/XNjySSbQzFcAAAAC/how-dare.gif)
