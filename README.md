# Loka

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Architecture
```bash
sh <(curl 'https://ash-hq.org/install/loka?install=phoenix') \
        && cd loka && mix igniter.install ash ash_phoenix \
        ash_postgres ash_authentication ash_authentication_phoenix \
        ash_admin ash_oban oban_web ash_archival live_debugger \
        ash_paper_trail cloak ash_cloak ash_money \
        --auth-strategy password --auth-strategy magic_link \
        --setup --yes
```

- **Account**: Manages user identity and personal data.
  - `User`: A person who can be a buyer or a studio owner. Handled by Ash Authentication.
  - `Address`: A user's billing or shipping address.

- **Studios**: Represents the ceramic studios on the platform.
  - `Studio`: The main entity with a `name`, `description`, and `owner`.
  - `Address`: The physical location of the studio with geocoordinates for mapping.

- **Inventory**: Contains the items that studios sell.
  - `Item`: A product sold by a `Studio`, with `name`, `description`, `price`, etc.
  - `Image`: For multiple pictures per `Item`.

- **Commerce**: Handles all shopping-related logic.
  - `Order`: A record of a transaction, linking a `User`, a `Studio`, and `OrderItem`s.
  - `OrderItem`: A line item in an order.
  - `Cart`: A temporary holder for a user's intended purchases.

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
