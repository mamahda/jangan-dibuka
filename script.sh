#!/bin/bash

ASSET_DIR="assets"
DB="metadata.csv"
LOG="activity.log"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log() {
    level=$1
    command=$2
    message=$3
    echo "[$(timestamp)] [$level] [$command] $message" >> "$LOG"
}

check_system() {
    if [[ ! -d "$ASSET_DIR" || ! -f "$DB" || ! -f "$LOG" ]]; then
        log "ERROR" "SYSTEM" "Missing components (assets/, metadata.csv, activity.log, or crontabs)"
        exit 1
    fi
}

# ======================
# SYNC
# ======================

sync_assets() {

    check_system

    # Detect new files
    for file in "$ASSET_DIR"/*; do
        [ -f "$file" ] || continue

        name=$(basename "$file")

        if ! grep -q "^$name," "$DB"; then

            size=$(stat -c%s "$file")
            ext="${name##*.}"
            created=$(date "+%Y-%m-%d_%H:%M:%S")

            echo "$name,$size,$ext,$created" >> "$DB"

            log "INFO" "SYNC" "Added new file $name"
        fi
    done

    # Clean missing files
    tmp=$(mktemp)

    while IFS=',' read -r name size ext created; do

        if [[ -f "$ASSET_DIR/$name" ]]; then
            echo "$name,$size,$ext,$created" >> "$tmp"
        else
            log "INFO" "SYNC" "Removed missing file $name from database"
        fi

    done < "$DB"

    mv "$tmp" "$DB"
}

# ======================
# AUTOSYNC
# ======================

autosync() {

    check_system

    job="*/5 * * * * $(pwd)/script.sh sync"

    crontab -l 2>/dev/null | grep -q "$job"

    if [[ $? -eq 0 ]]; then
        log "INFO" "AUTOSYNC" "Autosync already installed"
    else
        (crontab -l 2>/dev/null; echo "$job") | crontab -
        log "INFO" "AUTOSYNC" "Installed autosync every 5 minutes"
    fi
}

# ======================
# LIST
# ======================

list_assets() {

    check_system

    data=$(cat "$DB")

    ext=""
    sort=""

    for arg in "$@"; do
        case $arg in
            --ext=*)
                ext="${arg#*=}"
                ;;
            --sort=name)
                sort="name"
                ;;
            --sort=size)
                sort="size"
                ;;
        esac
    done

    if [[ -n "$ext" ]]; then
        data=$(echo "$data" | awk -F',' -v e="$ext" '$3==e')
    fi

    if [[ "$sort" == "name" ]]; then
        data=$(echo "$data" | sort -t',' -k1)
    elif [[ "$sort" == "size" ]]; then
        data=$(echo "$data" | sort -t',' -k2 -n)
    fi

    if [[ -z "$data" ]]; then
        log "INFO" "LIST" "Query returned empty result"
        exit
    fi

    printf "%-20s %-10s %-10s %-20s\n" "FILENAME" "SIZE" "EXT" "CREATED"
    echo "$data" | awk -F',' '{printf "%-20s %-10s %-10s %-20s\n",$1,$2,$3,$4}'

    log "INFO" "LIST" "Displayed database content"
}

# ======================
# STATS
# ======================

stats_assets() {

    check_system

    if [[ ! -s "$DB" ]]; then
        log "INFO" "STATS" "Accessed empty database"
        echo "Database kosong"
        exit
    fi

    total=$(wc -l < "$DB")

    total_size=$(awk -F',' '{sum+=$2} END {print sum}' "$DB")

    avg=$(awk -v t="$total_size" -v n="$total" 'BEGIN {print t/n}')

    largest=$(sort -t',' -k2 -nr "$DB" | head -n1)
    smallest=$(sort -t',' -k2 -n "$DB" | head -n1)

    echo "Total aset : $total"
    echo "Total size : $total_size bytes"
    echo "Average size : $avg bytes"

    echo
    echo "Aset terbesar:"
    echo "$largest"

    echo
    echo "Aset terkecil:"
    echo "$smallest"

    echo
    echo "Jumlah file per ekstensi:"
    awk -F',' '{count[$3]++} END {for (e in count) print e, count[e]}' "$DB"

    log "INFO" "STATS" "Generated statistics"
}

# ======================
# CREATE
# ======================

create_asset() {

    check_system

    filename=$1
    size=$2

    if [[ -z "$filename" || -z "$size" ]]; then
        log "ERROR" "CREATE" "Missing arguments"
        exit
    fi

    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        log "ERROR" "CREATE" "Invalid size: $size"
        exit
    fi

    if [[ -f "$ASSET_DIR/$filename" ]]; then
        log "ERROR" "CREATE" "File $filename already exists"
        exit
    fi

    head -c "$size" /dev/zero > "$ASSET_DIR/$filename"

    ext="${filename##*.}"
    created=$(date "+%Y-%m-%d_%H:%M:%S")

    echo "$filename,$size,$ext,$created" >> "$DB"

    log "INFO" "CREATE" "Created file $filename ($size bytes)"
}

# ======================
# DELETE
# ======================

delete_asset() {

    check_system

    filename=$1

    if [[ -z "$filename" ]]; then
        log "ERROR" "DELETE" "No filename provided"
        exit
    fi

    if [[ ! -f "$ASSET_DIR/$filename" ]]; then
        log "ERROR" "DELETE" "$filename not found"
        exit
    fi

    rm "$ASSET_DIR/$filename"

    grep -v "^$filename," "$DB" > temp && mv temp "$DB"

    log "INFO" "DELETE" "Deleted $filename"
}

# ======================
# COMMAND ROUTER
# ======================

case "$1" in

sync)
    sync_assets
    ;;

autosync)
    autosync
    ;;

list)
    shift
    list_assets "$@"
    ;;

stats)
    stats_assets
    ;;

create)
    create_asset "$2" "$3"
    ;;

delete)
    delete_asset "$2"
    ;;

esac
