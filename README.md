# Loka

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Initial Setup Command

```bash
sh <(curl 'https://ash-hq.org/install/loka?install=phoenix') \
        && cd loka && mix igniter.install ash ash_phoenix \
        ash_postgres ash_authentication ash_authentication_phoenix \
        ash_admin ash_oban oban_web ash_archival live_debugger \
        ash_paper_trail cloak ash_cloak ash_money \
        --auth-strategy password --auth-strategy magic_link \
        --setup --yes
```

## Architecture

Four Ash domains backed by PostgreSQL. All resources use UUIDv7 primary keys and policy-based authorization. Everything in the shop goes through **items**: an item may or may not be on sale.

- **Accounts** — User identity and authentication.
  - `User`: Buyers and studio owners. Auth via password + magic link (AshAuthentication). Tracks `email`, `hashed_password`, `confirmed_at` and `admin?` (only settable out of band, e.g. `Ash.Seed`). Exposes a `has_studio?` calculation and a `studio` relationship.

- **Studios** — Ceramic studios on the platform.
  - `Studio`: Belongs to a `User` (owner, unique — one studio per user) and has many `Item`s. Fields: `name`, `description`, `logo_path`, `street`, `house_number`, `city`, `postal_code`, `latitude`, `longitude`. Address is geocoded automatically from the postal code on create/update using the Swiss official locality index (`priv/data/localities.csv`). Archived instead of deleted (AshArchival); archiving a studio archives its items and their stock. The owner can restore it (`unarchive_studio`), which brings back the items archived together with it — items archived on their own before stay archived. Audited via AshPaperTrail.

- **Inventory** — What studios make and sell.
  - `Item`: A product with `name` and `description`, belonging to a `Studio` (always the creator's own studio). Has at most one current `Stock` and many ordered `Image`s. `in_stock?` is true when the current stock has pieces left; only then can the item be added to a cart. Archived instead of deleted (archiving archives its stock too) and restorable by the owner (`unarchive_item`, restoring the stock that was archived with it). Audited.
  - `Stock`: The price (CHF money) and `quantity` an item is on sale for. At most one current stock per item, enforced by a partial unique index on `item_id` where `archived_at IS NULL`. Price and quantity are edited in place; taking an item off sale archives its stock, and re-listing creates a new one. Only the item's owner can create stock for it (`Loka.Checks.ActorOwnsItem`). Audited.
  - `Image`: Ordered images for an item. Fields: `path`, `filename`, `position`. Files are stored under `priv/static/uploads/items/` (see `Loka.Changes.Image`).

- **Commerce** — Shopping cart and order management.
  - `Cart`: Holds a user's intended purchases. Can be anonymous (no `user_id`) or owned; an anonymous cart is merged into the user's cart after signing in. Anonymous carts older than 30 days are deleted daily via AshOban. Exposes an `item_count` aggregate and a `subtotal` calculation (CHF), which uses each item's current price and skips items no longer on sale.
  - `CartItem`: One piece of an `Item` in a `Cart` (adding the same item twice adds two rows). Only items in stock can be added. Items taken off sale or archived stay in the cart, shown as unavailable / removed.
  - `Order`: A placed order. Status lifecycle: `pending → paid → fulfilled` (or `cancelled`). Belongs to a `User`.
  - `OrderLine`: One line per `Stock` bought, with the `unit_price` captured at order time and a `quantity`.

## Shop routes

- `/` — Market: hero, interactive OSM map (from zoom 10 it filters the items to the visible area), item grid. Items not on sale show "Nicht online erhältlich", sold-out ones "Ausverkauft"; neither has an add-to-cart button.
- `/shop/item/:id` — Item detail: images, description, price and add-to-cart when on sale
- `/shop/studio/:id` — Studio page: logo, name, description, all items of that studio
- `/shop/cart` — Cart with line items and summary; removed items show "Dieser Artikel wurde entfernt" without a link

Archived studios and items are hidden everywhere in the shop.

## Studio management routes

- `/me/studio` — Open a studio, or see your (possibly archived) studio
- `/inventory/studio` — Edit the studio; archive it or restore an archived one. While archived, the items tab is disabled.
- `/inventory/items` — Your items, with price and stock; archived items can be restored from here
- `/inventory/items/new` — Create an item (with price and quantity)
- `/inventory/items/:id` — Edit an item and its images; put it on sale, change price and stock, take it off sale, or archive it

## Payments

Stripe + [`stripity_stripe`](https://hex.pm/packages/stripity_stripe) is the planned payment integration. TWINT is supported as a native Stripe payment method in Switzerland — it uses the standard Payment Intents API (`payment_method_types: ["twint"]`) alongside Visa/Mastercard, so no separate library or PSP contract is needed.

Constraints: CHF only, max 5,000 CHF per transaction, no manual capture.

Pricing: 1.9% + CHF 0.30 per transaction (same rate for cards and TWINT).

## Key libraries

- **Ash Framework** + AshPostgres, AshAuthentication, AshPhoenix, AshAdmin, AshOban, AshPaperTrail, AshArchival, AshMoney
- **Phoenix LiveView** with colocated JS hooks (`ColocatedHook`)
- **DaisyUI** (on top of Tailwind CSS v4) for UI components
- **Leaflet.js** for studio map (loaded via `app.js`; `ImageSlider` is also a global hook in `assets/js/image_slider.js`)
- **PhoenixTest** for LiveView tests, with **phoenix_test_playwright** for browser tests of the JS hooks

## Development

Requirements: Elixir/Erlang and Node.js as pinned in `.tool-versions` (e.g. `asdf install`), pnpm via corepack (`corepack enable pnpm`), and PostgreSQL (`podman compose up -d` starts it on port 5433).

```bash
mix setup          # install deps + create + migrate DB + seed
mix phx.server     # start dev server at localhost:4000
mix test           # run test suite (builds the JS first, includes browser tests)
mix precommit      # format + compile + test (run before committing)
mix ash.codegen <name>  # generate migrations after resource changes
```

After a DB reset (`mix ecto.reset`) restart a running `mix phx.server`, otherwise password sign-in fails until it's restarted.

The sender address of auth emails comes from `EMAIL_FROM` (default `noreply@example.com`).

### Browser tests

Tests in `test/loka_web/browser/` run in headless Chromium via Playwright and cover what LiveView tests can't: the JS hooks (add to cart, cart widget, map). One-time setup:

```bash
pnpm --dir assets install
pnpm --dir assets exec playwright install chromium
```

```bash
mix test test/loka_web/browser     # only the browser tests
mix test --exclude playwright      # everything except the browser tests
```

To watch them, pass `headless: false, slow_mo: 500` to `use PhoenixTest.Playwright.Case` in a test module. Browser tests can't reach the internet (no map tiles); the test server runs on port 4002.

## Users

Seeded by `priv/repo/seeds.exs`. Password is `password123` for all users.

- `admin@example.com` — admin (Ash Admin, LiveDashboard, Oban under `/admin`)
- `user@example.com` — normal user, with a cart containing an item that was removed afterwards
- `<city>@example.com` — studio owners, e.g. `grenchen@example.com`; cities with several studios are numbered: `bern1`–`bern3`, `zurich1`–`zurich6`
- `thun@example.com` — owner of an archived studio, to try restoring it
