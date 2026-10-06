# Changelog

## [2026-10-07] - Mileage update hardening

### Fixed
- `update-mileage` now requires the sender to be the network owner of a spawned vehicle with that plate.
- Mileage values are validated (numeric, >= 0, sane upper bound) and can no longer be rolled backwards.
