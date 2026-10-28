#!/usr/bin/python3 -I
"""Make a .torrent of a GitHub release's files, with the release itself as a permanent web seed.

  src/make-torrent.py TAG FILE...   ->  TAG.torrent next to the files, and prints the magnet link

The torrent is a folder named TAG holding FILE... . Its web seed (BEP 19) is the repo's release
download URL, so clients fetch pieces from https://github.com/OWNER/REPO/releases/download/TAG/FILE
when no peers are around; peers (DHT + the public trackers below) share with each other on top.
"""
import hashlib
import os
import sys
import time
import urllib.parse

REPO = "mbodigi/fedora-mangowm-remix"
PIECE = 8 * 1024 * 1024          # 8 MiB: a few hundred pieces for a ~4 GB release
TRACKERS = [
    "udp://tracker.opentrackr.org:1337/announce",
    "udp://open.stealth.si:80/announce",
    "udp://tracker.torrent.eu.org:451/announce",
    "udp://exodus.desync.com:6969/announce",
]


def bencode(x):
    if isinstance(x, int):
        return b"i%de" % x
    if isinstance(x, str):
        x = x.encode()
    if isinstance(x, bytes):
        return b"%d:%s" % (len(x), x)
    if isinstance(x, list):
        return b"l" + b"".join(bencode(i) for i in x) + b"e"
    if isinstance(x, dict):
        items = sorted((k.encode() if isinstance(k, str) else k, v) for k, v in x.items())
        return b"d" + b"".join(bencode(k) + bencode(v) for k, v in items) + b"e"
    raise TypeError(type(x))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    tag, files = sys.argv[1], sys.argv[2:]

    # pieces run across file boundaries, in file order (BitTorrent multi-file layout)
    pieces, buf = [], b""
    for f in files:
        with open(f, "rb") as fh:
            while chunk := fh.read(PIECE - len(buf)):
                buf += chunk
                if len(buf) == PIECE:
                    pieces.append(hashlib.sha1(buf).digest())
                    buf = b""
    if buf:
        pieces.append(hashlib.sha1(buf).digest())

    info = {
        "name": tag,
        "piece length": PIECE,
        "pieces": b"".join(pieces),
        "files": [{"length": os.path.getsize(f), "path": [os.path.basename(f)]} for f in files],
    }
    torrent = {
        "announce": TRACKERS[0],
        "announce-list": [[t] for t in TRACKERS],
        # web seed: base URL + name ("TAG") + "/" + file name = the release download URL
        "url-list": [f"https://github.com/{REPO}/releases/download/"],
        "comment": f"https://github.com/{REPO}/releases/tag/{tag}",
        "created by": "fedora-mangowm-remix make-torrent.py",
        "creation date": int(time.time()),
        "info": info,
    }
    out = os.path.join(os.path.dirname(files[0]) or ".", f"{tag}.torrent")
    with open(out, "wb") as fh:
        fh.write(bencode(torrent))

    btih = hashlib.sha1(bencode(info)).hexdigest()
    magnet = (f"magnet:?xt=urn:btih:{btih}&dn={urllib.parse.quote(tag)}"
              + "".join("&tr=" + urllib.parse.quote(t, safe="") for t in TRACKERS)
              + "&ws=" + urllib.parse.quote(torrent["url-list"][0], safe=""))
    print(f"{out}: {len(pieces)} pieces of {PIECE // 1048576} MiB, info hash {btih}")
    print(magnet)


if __name__ == "__main__":
    main()
