#!/bin/sh
# Workaround for https://github.com/dracut-ng/dracut-ng/issues/1983

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh


if getargbool 0 rd.net.wait-any-if; then
    GENERATOR_DIR="$2"
    [ -z "$GENERATOR_DIR" ] && exit 1
    [ -d "$GENERATOR_DIR/systemd-networkd-wait-online.service.d"] || mkdir -p "$GENERATOR_DIR/systemd-networkd-wait-online.service.d"

    {
        echo "[Service]"
        echo "ExecStart="
        echo "ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any"
    } > "$GENERATOR_DIR/systemd-networkd-wait-online.service.d/zz-wait-any-if.conf"
fi
