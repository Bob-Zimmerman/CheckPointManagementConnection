This is a Swift package to help work with [Check Point Software Technologies](https://www.checkpoint.com)'
firewall management server API.

[Documentation for Check Point's management API](https://sc1.checkpoint.com/documents/latest/APIs/index.html#introduction~v2%20)
can be found at their site.

How to Use This Package
========================================
The CheckPointManagement object represents a connection to a given management
server. You initialize it with either a username and password, or an API key.
You don't provide a username when logging in with an API key. I try to throw
useful errors representing the reasons logging in might fail. The errors are
NSError instances with localizable descriptions and recovery suggestions, so you
should be able to convert them directly to NSAlert for display in a modal.

Once you have logged in, you can make API calls by passing a call path and
JSON-compatible dictionary to makeRawApiCall. It returns a Data object, throwing
if it hits an error. You can then use whichever method you like to get the
information you want out of the Data object. For example, I typically make a
JSONDecoder and use its `decode<T>(_ type: T.Type, from data: Data) throws -> T
where T: Decodable` method with Decodable objects to get normal Swift objects.

The CheckPointManagement actor can be extended with support for nicer call
patterns. For example, I have defined a pushPolicy call which takes normal Swift
objects in its arguments and deals with converting them to the format Check
Point expects.

Testing
========================================
A lot of the code involves network calls, and obviously those are hard to test
without a target server to connect to. In my [CPAPI-Test-Target](https://github.com/Bob-Zimmerman/CPAPI-Test-Target/) repository,
there are directions and files to build a suitable test target. With such a
target running, the tests have 100% code coverage as of 2025-06-18.

As of 2025-06-18, the purely local tests cover 47.8% of the code.

`Test Support.swift` contains a set of variables which the tests use. If you
want to use your own test target, you can use it to customize the tests to match
your own environment.

I don't do any TLS trust workarounds (this is meant to work with a security
product, after all!), so the test target's certificate needs to be trusted. To
help with this, I have included `Certificate Truster.swift`. It contains a test
which isn't meant to exercise the package code. Instead, it connects to the
server specified in `TestData.url` and if the certificate isn't trusted, it
tries to add it to your login keychain and make it trusted for the domain.
The system will prompt you for your password if needed.

To-Do
========================================
- Collect exemplar errors from various versions. I'd like to support all the way
 back to R80, but that will take time.

- Tests which talk to a management server sometimes fail, then succeed when they
 are run again. I haven't yet spent the time to figure out what's wrong. I
 suspect it's some kind of problem on the management server like a rate limit.
 Test repetition partially works around this.
