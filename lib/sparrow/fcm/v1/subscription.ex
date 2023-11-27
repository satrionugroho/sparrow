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
end
