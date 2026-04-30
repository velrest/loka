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

Four Ash domains backed by PostgreSQL. All resources use UUIDv7 primary keys and policy-based authorization.

- **Accounts** — User identity and authentication.
  - `User`: Buyers and studio owners. Auth via password + magic link (AshAuthentication). Tracks `email`, `hashed_password`, `confirmed_at`. Exposes `has_studio?` calculation and a `studio` relationship.

- **Studios** — Ceramic studios on the platform.
  - `Studio`: Belongs to a `User` (owner). Fields: `name`. Soft-deleted via AshArchival; mutations audited via AshPaperTrail.

- **Inventory** — Products that studios sell.
  - `Item`: A product type with `name` and `description`. Has many `Stock` and `Image` records. Soft-deleted and audited.
  - `Stock`: One listing per item per studio. Fields: `quantity`, `price` (CHF money). Links `Item` → `Studio`. Soft-deleted and audited.
  - `Image`: Ordered images for an item. Fields: `path`, `filename`, `position`. Files managed via `Loka.Changes.Image`.

- **Commerce** — Shopping cart and order management.
  - `Cart`: Holds a user's intended purchases. Can be anonymous (no `user_id`) or owned. Supports merging an anonymous cart into a user cart on sign-in. Anonymous carts cleaned up daily via AshOban. Exposes `item_count` aggregate and `subtotal` calculation (CHF).
  - `CartStock`: Join table between `Cart` and `Stock`.
  - `Order`: A placed order. Status lifecycle: `pending → paid → fulfilled` (or `cancelled`). Belongs to a `User`.
  - `OrderLine`: One line per `Stock` entry in an order. Fields: `unit_price`, `quantity`.

## Users
Password is `password123` for all users
- user@loka.com Normal user
- studio1@loka.com Studio 1
- studio2@loka.com Studio 2

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
