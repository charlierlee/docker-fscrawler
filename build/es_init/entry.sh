#!/bin/sh

set -e

if [ -z "$ES_URL" ]; then
  echo "Missing env var ES_URL"
  exit 1
fi

until curl --silent -XPUT -H "Content-Type: application/json" -d @example_pipeline.json $ES_URL/_ingest/pipeline/example_pipeline?pretty; do
    echo 'error'
    sleep 5
done

echo 'success'
