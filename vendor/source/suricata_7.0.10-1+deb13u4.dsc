-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 3.0 (quilt)
Source: suricata
Binary: suricata
Architecture: linux-any
Version: 1:7.0.10-1+deb13u4
Maintainer: Pierre Chifflier <pollux@debian.org>
Uploaders: Sascha Steinbiss <satta@debian.org>
Homepage: https://suricata.io
Standards-Version: 4.6.2
Vcs-Browser: https://salsa.debian.org/pkg-suricata-team/pkg-suricata
Vcs-Git: https://salsa.debian.org/pkg-suricata-team/pkg-suricata.git
Testsuite: autopkgtest
Testsuite-Triggers: @builddeps@, geoip-database, procps, systemd
Build-Depends: debhelper-compat (= 13), dh-python, libbpf-dev (>= 1:0.7.0) [amd64 arm64 armel armhf i386 ppc64el s390x ppc64 sparc64 x32], clang [amd64 arm64 armel armhf i386 ppc64el s390x ppc64 sparc64 x32], llvm [amd64 arm64 armel armhf i386 ppc64el s390x ppc64 sparc64 x32], libcap-ng-dev, libelf-dev [amd64 arm64 armel armhf i386 ppc64el s390x ppc64 sparc64 x32], libevent-dev, libgeoip-dev, libhiredis-dev, libjansson-dev, libluajit-5.1-dev [i386 amd64 powerpc mips mipsel armel armhf], libhyperscan-dev (>= 4.4.0) [i386 amd64 x32], rustc (>= 1.61.0), cargo (>= 0.29.0), liblz4-dev, libmagic-dev, libmaxminddb-dev, libnet1-dev | libnet-dev, libnetfilter-log-dev, libnetfilter-queue-dev, libnspr4-dev, libnss3-dev, libpcap-dev, libpcre2-dev, libyaml-dev, python3:any, zlib1g-dev | libz-dev, libhtp-dev (>= 1:0.5.50), procps, dpdk-dev [amd64 arm64 riscv64 ppc64el], libnuma-dev [amd64 arm64 riscv64 ppc64el]
Package-List:
 suricata deb net optional arch=linux-any
Checksums-Sha1:
 2e963aae42eccea7bfe9e03ba4af18e2b8bfc0e5 18181672 suricata_7.0.10.orig.tar.xz
 12424a08f26cc09cc0dfdfec4d608b585aaf148e 47612 suricata_7.0.10-1+deb13u4.debian.tar.xz
Checksums-Sha256:
 8956f7de394652b7cb7ede4a1715b0c46798ac825d11f08a5785b07dae7a945a 18181672 suricata_7.0.10.orig.tar.xz
 1f04522e19ac2897962978ee148b0bb49e68297a049e93d53201493dfed1929c 47612 suricata_7.0.10-1+deb13u4.debian.tar.xz
Files:
 447c0839bce5b80006d791688ef31abf 18181672 suricata_7.0.10.orig.tar.xz
 610c736746a6d4da02239f422caedea4 47612 suricata_7.0.10-1+deb13u4.debian.tar.xz

-----BEGIN PGP SIGNATURE-----

iIoEARYKADIWIQTjqpLKhithiGov9EruqOTPfpjPmQUCaem5gRQcZGV2QGFuZHJl
YXMtZG9scC5kZQAKCRDuqOTPfpjPmW8oAP96rOP1y/jKLL10uHTOw5q1iphwcZkq
7XG0MbeLiKS6OQD+I7qPZ9lYMIPbhXnW30+ISSzTeFaYS1gPfwSYDB6bigM=
=K/CX
-----END PGP SIGNATURE-----
