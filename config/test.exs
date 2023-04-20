import Config

config :sparrow, Sparrow.H2ClientAdapter, %{
  adapter: Sparrow.H2ClientAdapter.Mock
}

config :sparrow, pool_enabled: false
