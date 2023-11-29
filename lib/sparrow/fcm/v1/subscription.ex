defmodule Sparrow.FCM.V1.Subscription do
  @moduledoc """
  Struct representing FCM.V1 subscription

  For detatils on the FCM documentation structure and see the following links:
    * https://firebase.google.com/docs/cloud-messaging/manage-topics
  """

  @type operation :: :batchAdd | :batchRemove
  @type t :: %__MODULE__{
    tokens: [String.t()],
    topic: String.t(),
    operation: operation()
  }
  @type response :: %{
    success: integer(),
    failure: integer(),
    errors: [String.t()]
  }

  @default_endpoint "https://iid.googleapis.com/iid"

  defstruct [:tokens, :topic, :operation]

  @doc """
  Create new Subscription

  ## Arguments
    
    * `tokens` - Can be single token or list of tokens. Target to send a message to.
    * `topic` - Can subscribe to a topic (required).
  """
  @spec subscribe([String.t()], String.t()) :: {:ok, t()} | {:error, String.t()}
  def subscribe([_| _] = tokens, topic) do
    case topic do
      "" -> {:error, "topic cannot be empty"}
      _ -> {:ok, %__MODULE__{tokens: tokens, topic: get_topic(topic), operation: :batchAdd}}
    end
  end
  def subscribe(token, topic), do: subscribe([token], topic)

  @doc """
  Create new Unsubscription

  ## Arguments
    
    * `tokens` - Can be single token or list of tokens. Target to send a message to.
    * `topic` - Can subscribe to a topic (required).
  """
  @spec unsubscribe([String.t()], String.t()) :: {:ok, t()} | {:error, String.t()}
  def unsubscribe([_| _] = tokens, topic) do
    case topic do
      "" -> {:error, "topic cannot be empty"}
      _ -> {:ok, %__MODULE__{tokens: tokens, topic: get_topic(topic), operation: :batchRemove}}
    end
  end
  def unsubscribe(token, topic), do: unsubscribe([token], topic)

  defp get_topic("/topics/" <> _t = topic), do: topic
  defp get_topic(topic), do: "/topics/#{topic}"

  @spec path(operation() | t()) :: String.t()
  def path(%__MODULE__{operation: op}), do: path(op)
  def path(operation) when operation in [:batchAdd, :batchRemove] do
    "/iid/v1:#{operation}"
  end
  def path(operation) do
    _ = :logger.error(%{
      error: :subscription,
      message: "#{inspect operation} not supported",
    }, %{
      module: __MODULE__,
      funtion: :path
    })
  end

  def body(%__MODULE__{} = subs) do
    %{
      "to" => subs.topic,
      "registration_tokens" => subs.tokens
    }
  end

  def list(token) do
    case Sparrow.PoolsWarden.choose_pool(:fcm) do
      nil ->
        _ =
          :logger.error(%{
            message: "Unable to select connection pool",
          },
            what: :connection_pool,
            reason: :unable_to_find,
            pool_type: inspect(:fcm),
            tags: [:list, :fcm]
          )

        {:error, :configuration_error}
      pool -> do_get_list(pool, token)
    end
  end

  defp do_get_list(wpool, token) do
    project = Sparrow.FCM.V1.ProjectIdBearer.get_project_id(wpool)
    bearer  = Sparrow.FCM.V1.TokenBearer.get_token(project)
    url     = "#{@default_endpoint}/info/#{token}?details=true"
    headers = [
      {"access_token_auth", true},
      {"authorization", "Bearer #{bearer}"},
      {"content-type", "application/json"},
    ]

    HTTPoison.get(url, headers)
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        resp   = Jason.decode!(response.body)
        topics = Map.get(resp, "rel", %{}) |> Map.get("topics", [])
        {:ok, %{topics: topics, scope: Map.get(resp, "scope")}}
      {:error, _err} = error -> error
    end
  end
end
