from __future__ import annotations

import argparse
import time

from jose import jwt


def main() -> None:
    parser = argparse.ArgumentParser(description="Mint a dev JWT for ATX_AI testing")
    parser.add_argument("--secret", required=True, help="HS256 secret")
    parser.add_argument("--sub", required=True, help="User id (sub)")
    parser.add_argument("--ttl", type=int, default=3600, help="Seconds to live")
    args = parser.parse_args()

    now = int(time.time())
    payload = {
        "sub": args.sub,
        "iat": now,
        "exp": now + int(args.ttl),
    }
    token = jwt.encode(payload, args.secret, algorithm="HS256")
    print(token)


if __name__ == "__main__":
    main()
