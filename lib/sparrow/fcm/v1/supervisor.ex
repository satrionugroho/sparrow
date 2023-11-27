defmodule Sparrow.FCM.V1.Supervisor do
  @moduledoc """
  Main FCM supervisor.
  Supervises FCM token bearer and pool supervisor.
  """
  use Supervisor

  @spec start_link([Keyword.t()]) :: Supervisor.on_start()
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  @spec init([Keyword.t()]) ::
          {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}}
  def init(raw_fcm_config) do
    source = goth_source_from_config(raw_fcm_config)
    children = [
      Sparrow.FCM.V1.ProjectIdBearer,
      {Sparrow.FCM.V1.Pool.Supervisor, raw_fcm_config},
      {Sparrow.FCM.V1.Pool.Subscription, raw_fcm_config},
      {Goth, name: Sparrow.FCM.V1.TokenBearer, source: source}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp goth_source_from_config([config | _cfg]) do
    config
    |> Keyword.get(:path_to_json)
    |> File.read()
    |> case do
      {:ok, file} -> {:service_account, Jason.decode!(file)}
      err -> err
    end
  end
end
