# Tasks
Move the finished tasks to Done

## Quality checks
- Any funcitonality which is missing tests
- Code quality check
- Any templates that could be simplified
- Any code that could be simplified

## TODO
- Map still not zooming to user location in firefox and chrome after permission is granted, remove all the console.logs in the leaflet compoenent again
- At some point, we well need to add some logic so stock is reserved for a user for some time after adding it to cart and the display of remaining items need to take this into consideration.
- **Pre-launch:** Update sender email in `send_password_reset_email.ex`, `send_new_user_confirmation_email.ex`, `send_magic_link_email.ex` (currently `noreply@example.com`)

## Done
- Map zooms to user location when permission granted (geolocation → `flyTo` zoom 11); stock list only filters to visible bounds at zoom ≥ 10 so zooming out still shows all studios
- Moved all LiveComponents into `./lib/loka_web/live/components` (`add_to_cart_component.ex`, `studio_map_component.ex`, `address_input_component.ex`)
- Removed redundant `handle_params` assigning `current_path` in views covered by `AssignCurrentPath` hook
- Policy sanity check: fixed Studio create policy — `forbid_if actor_attribute_equals(:has_studio?, true)` enforces one studio per user; added DB-level `unique_owner` identity
- Fixed `cart_live.ex` — replaced `Ash.destroy!` + `authorize?: false` with `Commerce.remove_from_cart!`
- Added tests for `cart_live.ex` (11 tests covering anonymous and authenticated flows)
- Checked for TODOs in code (only pre-launch email config remains)
- Squashed 20 incremental migrations into single `init` migration
