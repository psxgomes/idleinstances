#!/bin/bash

THIRTY_DAYS_AGO=$(date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ")

echo "Instances stopped for more than 30 days across the organization:"
echo "-------------------------------------------------------------"

PROJECTS=$(gcloud projects list --format="value(projectId)")

for PROJECT in $PROJECTS; do
    echo "Checking project: $PROJECT"
    echo "----------------"
    
    ZONES=$(gcloud compute zones list --format="value(name)")
    
    for ZONE in $ZONES; do

        gcloud compute instances list \
            --project="$PROJECT" \
            --filter="status:TERMINATED" \
            --format="value(name,zone,lastStopTimestamp)" \
            --zones="$ZONE" 2>/dev/null | while read -r NAME ZONE LAST_STOP; do
                
                if [ -n "$LAST_STOP" ]; then

                    STOP_TIME=$(date -d "$LAST_STOP" +%s 2>/dev/null)
                    LIMIT_TIME=$(date -d "$THIRTY_DAYS_AGO" +%s 2>/dev/null)

                    if [ -n "$STOP_TIME" ] && [ "$STOP_TIME" -lt "$LIMIT_TIME" ]; then
                        echo "Project: $PROJECT"
                        echo "Name: $NAME"
                        echo "Zone: $ZONE"
                        echo "Stopped since: $LAST_STOP"
                        echo "----------------"
                    fi
                fi
            done
    done
    echo "-------------------------------------------------------------"
done