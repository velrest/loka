defmodule Loka.Secrets do
  @moduledoc "Provides secrets to AshAuthentication, such as the token signing secret."

  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Loka.Accounts.User, _opts, _context) do
    Application.fetch_env(:loka, :token_signing_secret)
  end
end
