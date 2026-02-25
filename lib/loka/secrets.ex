defmodule Loka.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Loka.Accounts.User, _opts, _context) do
    Application.fetch_env(:loka, :token_signing_secret)
  end
end
