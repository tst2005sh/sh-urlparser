Shell URL Parser
================

Some POSIX shell functions to help you to parser URL/URI.
Not perfect but better than nothing ;-)


See [URL on wikipedia](https://en.wikipedia.org/wiki/Uniform_resource_locator)

```
scheme:[//[user:password@]domain[:port]][/]path[?query][#fragment]
```

```
https://username:password@www.example.com:443/path/file.name?query=string#anchor
|___|   |______| |______| |_____________| |_||_____________||___________||_____|
  |        |       |           |          |         |             |         |
scheme   user   password     domain      port      path         query   fragment
|______________________________________________________________________________|
                                       |
                                      url
```


Tests
=====

```
$ sh test.url-parser.sh
[PASS] test-001 :  (http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html)
[PASS] test-002 :  (http://[1080:0:0:0:8:800:200C:417A]/index.html)
[PASS] test-003 :  (http://[3ffe:2a00:100:7031::1])
[PASS] test-004 :  (http://[1080::8:800:200C:417A]/foo)
[PASS] test-005 :  (http://[::192.9.5.5]/ipng)
[PASS] test-006 :  (http://[::FFFF:129.144.52.38]:80/index.html)
[PASS] test-007 :  (http://[2010:836B:4179::836B:4179])
[PASS] test-008 :  (user:pass@host)
[PASS] test-009 :  (user:pass@host:)
[PASS] test-010 :  (user:pass@host:xx/yy)
[PASS] test-011 :  (user:pass@[::1]:xx/yy:zz)
[PASS] test-012 :  (https://user:pass@[::1]:443/path/to/get?truc:machin#an)
[PASS] test-013 :  (https://user:pass@host:port/uri)
[FAIL] test-014 :  (http://host?xxx=yyy/zzz)                    wanted '74bf1d89' but got 'a0e78b84'
[FAIL] test-015 :  (http://[host]?xxx=yyy/zzz)                    wanted '397aa7dd' but got '5f44d1b1'
```

See also
========



TODO
====

 * fix bug to pass all tests


License
=======

MIT - TsT 2015
