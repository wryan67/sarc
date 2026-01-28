#!/bin/ksh
set -a

ZVOL="bones"
PROCDATE=$(date +%Y%m%d)
SNAPNAME="cold-backup-$PROCDATE"
FUDGE=0.80
TOTAL_EST_BYTES=0

die() {
  echo "ERROR: $*"
  exit 2
}

cleanup() {
  rm -f /tmp/zfs-send.*.pipe 2>/dev/null
  pkill -P $$ 2>/dev/null
}

trap cleanup EXIT INT TERM

VM_NAME=$1
[[ -z $VM_NAME ]] && die "Usage: $0 <vm_name>"

rm -f /tmp/zfs-send.*.pipe 2>/dev/null

ARCH="$VM_NAME.$PROCDATE.sarc"
SUM_FILE="$VM_NAME.$PROCDATE.sums"
CLI_ARGS=""

# Clear or create the checksum file
true > "$SUM_FILE"

VM_ID=$(qm list 2>/dev/null | grep " $VM_NAME " | awk '{print $1}')
[[ -z $VM_ID ]] && die "Could not find ID for VM: $VM_NAME"

echo "Stopping VM $VM_NAME ($VM_ID)..."
qm stop $VM_ID || die "Initial stop command failed"

if ! qm wait $VM_ID --timeout 30; then
    die "VM $VM_NAME failed to stop within 30 seconds. Aborting backup."
fi

DATASETS=$(zfs list -H -o name -r "$ZVOL/qemu/$VM_NAME" | awk -F/ '{if (NF>3) print $NF}')
for i in $DATASETS; do
    SIZE=$(zfs get -Hpo value referenced "$ZVOL/qemu/$VM_NAME/$i" 2>/dev/null)
    (( TOTAL_EST_BYTES += SIZE ))
done
TOTAL_EST_BYTES=$(echo "$TOTAL_EST_BYTES * $FUDGE" | bc | cut -d. -f1)


for i in $DATASETS; do
    zfs snapshot "$ZVOL/qemu/$VM_NAME/$i@$SNAPNAME" 2>/dev/null
    ZPIPE="/tmp/zfs-send.$i.pipe"
    rm -f "$ZPIPE"
    mkfifo "$ZPIPE"
    
    CLI_ARGS="$CLI_ARGS $i.$PROCDATE.img.gz::$ZPIPE"

    ( 
        zfs send "$ZVOL/qemu/$VM_NAME/$i@$SNAPNAME" | \
        tee >(sha256sum | awk "{print \$1 \"  $i.$PROCDATE.img\"}" >> "$SUM_FILE") | \
        pigz -c > "$ZPIPE" 
    ) &
done

# Calculate checksum for the config file separately since it's piped directly
VM_CONF=$(qm config $VM_ID 2>/dev/null)
echo "$VM_CONF" | sha256sum | awk "{print \$1 \"  $VM_NAME.$PROCDATE.conf\"}" >> "$SUM_FILE"

echo "$VM_CONF" |\
    sarc -vs "${TOTAL_EST_BYTES}b" -a "$ARCH" "$VM_NAME.$PROCDATE.conf::-" $CLI_ARGS || die "Backup failed"

echo ""
echo "Checksums saved to: $SUM_FILE"
sarc -a "$ARCH" -l
