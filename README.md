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

- Account: Any user related data for login or billing
  - User
  - Address
  - ...
- Inventory: All shop related resrouces for managing sells
  - Item
  - 
- Shop
  - Cart
  - Payments

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
