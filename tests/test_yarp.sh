#!/usr/bin/env bash
# Strict YARP self-test (INSIDE container) — no installs, no GUI
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "MISSING: $1"; exit 2; }; }
die()  { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

need yarp
need yarpserver
need yarp-config
need python3

export YARP_NAMESPACE="/yarp_test_$$"
echo "YARP namespace: $YARP_NAMESPACE"

# 1) start server
yarpserver >/dev/null 2>&1 &
YSRV=$!
trap 'kill $YSRV >/dev/null 2>&1 || true' EXIT

# 2) wait server ready
timeout 10 bash -c 'until yarp check >/dev/null 2>&1; do sleep 0.1; done' || die "yarpserver not ready"
ok "yarpserver is up"

# 3) quick CLI sanity
yarp-config --help >/dev/null 2>&1 || die "yarp-config not responding"
yarp plugin --list   >/dev/null 2>&1 || die "cannot list plugins"
ok "CLI + plugins OK"

# 4) Python round-trip with polling (no setConnectionTimeout)
python3 - <<'PY'
import os, sys, random, time
try:
    import yarp
except Exception as e:
    print("FAIL: cannot import yarp:", e, file=sys.stderr)
    sys.exit(3)

msg = f"hello_yarp_{random.randint(1,10**9)}"
yarp.Network.init()
try:
    if not yarp.Network.checkNetwork():
        print("FAIL: YARP network not reachable from Python", file=sys.stderr)
        sys.exit(4)

    in_port  = yarp.BufferedPortBottle()
    out_port = yarp.BufferedPortBottle()

    in_name  = "/in"
    out_name = "/out"

    if not in_port.open(in_name):
        print("FAIL: cannot open", in_name, file=sys.stderr); sys.exit(5)
    if not out_port.open(out_name):
        print("FAIL: cannot open", out_name, file=sys.stderr); sys.exit(6)

    # Ensure connection (retry briefly to avoid races)
    connected = False
    for _ in range(30):
        if yarp.Network.connect(out_name, in_name):
            connected = True
            break
        yarp.delay(0.1)
    if not connected:
        print("FAIL: cannot connect /out -> /in", file=sys.stderr); sys.exit(7)

    # Send
    bw = out_port.prepare()
    bw.clear()
    bw.addString(msg)
    out_port.write()

    # Poll for up to ~2 seconds (20 * 0.1s)
    got = None
    for _ in range(20):
        got = in_port.read(False)  # non-blocking
        if got is not None:
            break
        yarp.delay(0.1)

    if got is None:
        print("FAIL: timed out waiting for message", file=sys.stderr); sys.exit(8)

    if got.toString() != msg:
        print(f"FAIL: payload mismatch: '{got.toString()}' != '{msg}'", file=sys.stderr)
        sys.exit(9)

    print("OK: Python round-trip")
finally:
    try:
        out_port.close()
        in_port.close()
    except:
        pass
    yarp.Network.fini()
PY

# 5) clean shutdown
kill "$YSRV" >/dev/null 2>&1 || true
wait "$YSRV" 2>/dev/null || true
trap - EXIT

echo "ALL YARP TESTS PASSED"
