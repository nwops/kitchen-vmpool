# Kitchen-Vmpool

## Unreleased
 * Major refactor of file based stores
 * changes instances to size
 * removes separate pool_name in vmpool config
 * removes reference too payload_file since it is provider specific
 * Creates base gitlabstore class, moves gitlab monkey patch
 
## v0.2.0
 * adds a gitlab commit store
 * Fix accounting bugs with used and pool instances