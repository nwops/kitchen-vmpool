# Kitchen-Vmpool

## Unreleased

## v0.3.2
 * Destroy process does not output correct hostname
 * Delete old instances from used_instances pool

## v0.3.1
 * Ensures CRUD methods are public
 
## v0.3.0
 * Major refactor of file based stores
 * changes instances to size
 * removes separate pool_name in vmpool config
 * removes reference too payload_file since it is provider specific
 * Creates base gitlabstore class, moves gitlab monkey patch
 
## v0.2.0
 * adds a gitlab commit store
 * Fix accounting bugs with used and pool instances