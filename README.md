# Scraper

A Phoenix web application for scraping web pages and extracting links.

## Requirements

- **Elixir**: 1.18 or higher
- **Erlang/OTP**: 25 or higher (compatible with Elixir 1.18+)
- **PostgreSQL**: 14 or higher

## Setup

1. **Install dependencies**
   ```bash
   mix deps.get
   ```

2. **Database setup**
   - Ensure PostgreSQL is running
   - Create and migrate the database:
   ```bash
   mix ecto.setup
   ```

## Running the Application

* **Development server**: `mix phx.server`
* **Interactive shell**: `iex -S mix phx.server`

Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Testing

* **Run all tests**: `MIX_ENV=test mix test`
* **Run tests with coverage**: `MIX_ENV=test mix coveralls`

## Database Commands

* **Reset database**: `mix ecto.reset`
* **Run migrations**: `mix ecto.migrate`
* **Rollback migration**: `mix ecto.rollback`

## Production Deployment

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
