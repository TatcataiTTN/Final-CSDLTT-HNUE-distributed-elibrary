#!/bin/bash

# Auto Sync Loop - Runs data synchronization every 60 seconds

echo "Starting Auto Sync Loop..."
echo "Press [CTRL+C] to stop."

while true; do
    echo "----------------------------------------"
    echo "Running sync at $(date)..."
    php force_sync_all.php
    echo "Sync complete."
    echo "Sleeping for 60 seconds..."
    sleep 60
done
