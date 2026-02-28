#!/bin/bash

ASSETS_DIR="./assets/"
DB_FILE="./metadata.csv"
LOG_FILE="./activity.log"
CRON_FILE="./crontabs"

log_message() {
    local level=$1
    local command=$2
    local message=$3
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] [$command] $message" >> "$LOG_FILE"
}

check_requirements() {
    if [[ ! -d "$ASSETS_DIR" || ! -f "$DB_FILE" || ! -f "$LOG_FILE" || ! -f "$CRON_FILE" ]]; then
        local error_msg="Missing components (assets/, metadata.csv, activity.log, or crontabs)"
        echo "Error: $error_msg"
        log_message "ERROR" "SYSTEM" "$error_msg"
        exit 1
    fi
}

do_sync() {
    local current_time=$(date +"%Y-%m-%d_%H:%M:%S")

    for filepath in "$ASSETS_DIR"/*; do
        [ -e "$filepath" ] || continue
        filename=$(basename "$filepath")

        if ! grep -q "^$filename," "$DB_FILE"; then
            size=$(stat -c%s "$filepath")
            ext="${filename##*.}"
            if [[ "$filename" == "$ext" ]]; then ext="none"; fi
            echo "$filename,$size,${ext,,},$current_time" >> "$DB_FILE"
            log_message "INFO" "SYNC" "Added new file $filename"
        fi
    done

    while IFS=, read -r filename size ext created_at; do
        if [[ ! -f "$ASSETS_DIR/$filename" ]]; then
            sed -i "/^$filename,/d" "$DB_FILE"
            log_message "INFO" "SYNC" "Removed missing file $filename from database"
        fi
    done < "$DB_FILE"

    echo "Sync completed."
}

do_list() {
    local sort_type="none"
    local ext_filter=""

    for arg in "$@"; do
        case $arg in
            --sort=name) sort_type="name" ;;
            --sort=size) sort_type="size" ;;
            --ext=*) ext_filter="${arg#*=}" ;;
        esac
    done

    local data=$(cat "$DB_FILE")

    if [[ -n "$ext_filter" ]]; then
        data=$(echo "$data" | awk -F, -v ext="$ext_filter" '$3 == ext')
    fi

    if [[ -z "$data" ]]; then
        echo "No results found."
        log_message "INFO" "LIST" "Query returned empty result"
        return
    fi

    if [[ "$sort_type" == "name" ]]; then
        data=$(echo "$data" | sort -t, -k1)
    elif [[ "$sort_type" == "size" ]]; then
        data=$(echo "$data" | sort -t, -k2 -n)
    fi

    echo "$data" | column -s, -t
    log_message "INFO" "LIST" "Displayed database content"
}

do_stats() {
    if [[ ! -s "$DB_FILE" ]]; then
        echo "Database is empty."
        log_message "INFO" "STATS" "Accessed empty database"
        return
    fi

    awk -F, '
    {
        count++;
        sum += $2;
        exts[$3]++;
        if (NR == 1 || $2 > max) { max = $2; max_file = $1 }
        if (NR == 1 || $2 < min) { min = $2; min_file = $1 }
    }
    END {
        printf "Total files         : %d\n", count
        printf "Total size (bytes)  : %d\n", sum
        printf "Average size        : %.0f\n\n", sum/count
        printf "Largest file        : %s (%d bytes)\n", max_file, max
        printf "Smallest file       : %s (%d bytes)\n\n", min_file, min
        print "File count by extension:"
        for (e in exts) printf "%s  : %d\n", e, exts[e]
    }' "$DB_FILE"

    log_message "INFO" "STATS" "Generated statistics"
}

do_create() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Error: Missing arguments."
        log_message "ERROR" "CREATE" "Missing arguments"
        exit 1
    fi

    local filename=$1
    local size=$2

    if [[ ! "$size" =~ ^[0-9]+$ ]]; then
        echo "Error: Size must be a positive number."
        log_message "ERROR" "CREATE" "Invalid size: $size"
        exit 1
    fi

    if [[ -f "$target" ]]; then
        echo "Error: File already exists."
        log_message "ERROR" "CREATE" "File $filename already exists"
        exit 1
    fi

    truncate -s "$size" "$ASSETS_DIR/$filename"

    local current_time=$(date +"%Y-%m-%d_%H:%M:%S")
    local ext="${filename##*.}"
    if [[ "$filename" == "$ext" ]]; then ext="none"; fi
    echo "$filename,$size,${ext,,},$current_time" >> "$DB_FILE"

    echo "File $filename created successfully."
    log_message "INFO" "CREATE" "Created file $filename ($size bytes)"
}

do_delete() {
    local filename=$1
    if [[ -z "$filename" ]]; then
        echo "Error: Provide filename to delete."
        log_message "ERROR" "DELETE" "No filename provided"
        exit 1
    fi

    if [[ -f "$ASSETS_DIR/$filename" ]]; then
        rm "$ASSETS_DIR/$filename"
        sed -i "/^$filename,/d" "$DB_FILE"
        echo "File $filename deleted."
        log_message "INFO" "DELETE" "Deleted $filename"
    else
        echo "Error: File not found."
        log_message "ERROR" "DELETE" "$filename not found"
    fi
}

do_autosync() {
    abs_path=$(realpath "$0")
    log_path=$(realpath "$LOG_FILE")
    cat > "$CRON_FILE" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

*/5 * * * * /bin/bash $abs_path sync >> $log_path 2>&1
EOF
    if [[ -f "$CRON_FILE" ]]; then
        crontab "$CRON_FILE"
        echo "Autosync installed (every 5 minutes)."
        log "INFO" "AUTOSYNC" "Installed autosync every 5 minutes"
    else
        error_exit "Crontab file not found" "AUTOSYNC"
    fi
}

check_requirements

case "$1" in
    sync) do_sync ;;
    list) shift; do_list "$@";;
    stats) do_stats;;
    create) do_create "$2" "$3";;
    delete) do_delete "$2";;
    autosync) do_autosync;;
    *)
        echo "Usage: ./filedb.sh {sync|list|stats|create|delete|autosync}"
        ;;
esac
