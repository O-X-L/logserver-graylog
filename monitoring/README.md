# Graylog Monitoring

## Graylog Status / Health

1. Create a read-only user in your Graylog instance
2. Get the status and health from the API:

  ```
  curl http://${GL_USER}:${GL_PWD}@localhost:9000/api/system/indexer/cluster/health 2>/dev/null
  ```

3. Parse the JSON in your Monitoring-System
4. Trigger if `health` is not `green`

## OpenSearch Status / Health

1. Get the status and health from the API:

  ```
  curl http://localhost:9200/_cluster/health 2>/dev/null
  ```

2. Parse the JSON in your Monitoring-System
3. Trigger if `status` is not `green`

## Graylog Journal

Check-out the `graylog_journal_size.sh` script.

Alternatively you can query the API.

You might trigger if the journal is >50% full. This indicates that the Graylog instance is not able to process all the logs it receives.
