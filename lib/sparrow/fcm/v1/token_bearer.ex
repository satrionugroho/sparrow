defmodule Sparrow.FCM.V1.TokenBearer do
  @moduledoc """
  Module providing FCM token.
  """

  require Logger

  @spec get_token(String.t()) :: String.t() | nil
  def get_token(_account) do
    {:ok, token_map} = Goth.fetch(__MODULE__)

    _ =
      Logger.debug("Fetching FCM token",
        worker: :fcm_token_bearer,
        what: :get_token,
        result: :success
      )

    Map.get(token_map, :token)
  end
end
