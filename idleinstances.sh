#!/bin/bash

# Define the output file
OUTPUT_FILE="stopped_instances_report.txt"

# Define the cutoff date (30 days ago) in ISO 8601 format
THIRTY_DAYS_AGO=$(date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ")

# Start writing to the file
echo "Instances stopped for more than 30 days across the organization:" > "$OUTPUT_FILE"
echo "-------------------------------------------------------------" >> "$OUTPUT_FILE"

# List all projects in the organization that the user has access to
PROJECTS=$(gcloud projects list --format="value(projectId)")

# Iterate through each project
for PROJECT in $PROJECTS; do
    echo "Checking project: $PROJECT" >> "$OUTPUT_FILE"
    echo "----------------" >> "$OUTPUT_FILE"
    
    # List all available zones
    ZONES=$(gcloud compute zones list --format="value(name)")
    
    # Iterate through each zone in the current project
    for ZONE in $ZONES; do
        # List instances in the current zone with TERMINATED status and timestamp
        gcloud compute instances list \
            --project="$PROJECT" \
            --filter="status:TERMINATED" \
            --format="value(name,zone,lastStopTimestamp)" \
            --zones="$ZONE" 2>/dev/null | while read -r NAME ZONE LAST_STOP; do
                
                # Check if LAST_STOP is not empty
                if [ -n "$LAST_STOP" ]; then
                    # Convert dates to seconds since epoch for comparison
                    STOP_TIME=$(date -d "$LAST_STOP" +%s 2>/dev/null)
                    LIMIT_TIME=$(date -d "$THIRTY_DAYS_AGO" +%s 2>/dev/null)

                    # Check if the instance has been stopped for more than 30 days
                    if [ -n "$STOP_TIME" ] && [ "$STOP_TIME" -lt "$LIMIT_TIME" ]; then
                        echo "Project: $PROJECT" >> "$OUTPUT_FILE"
                        echo "Name: $NAME" >> "$OUTPUT_FILE"
                        echo "Zone: $ZONE" >> "$OUTPUT_FILE"
                        echo "Stopped since: $LAST_STOP" >> "$OUTPUT_FILE"
                        echo "----------------" >> "$OUTPUT_FILE"
                    fi
                fi
            done
    done
    echo "-------------------------------------------------------------" >> "$OUTPUT_FILE"
done

echo "Report generated in $OUTPUT_FILE"
