defmodule KinesisClient.Stream.Shard do
  @moduledoc false
  use Supervisor
  alias KinesisClient.Stream.Shard.{Lease, Pipeline}
  import KinesisClient.Util

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: args[:shard_name])
  end

  def init(opts) do
    lease_opts = [
      app_name: opts[:app_name],
      coordinator_name: opts[:coordinator_name],
      shard_id: opts[:shard_id],
      lease_owner: opts[:lease_owner]
    ]

    pipeline_opts = [
      app_name: opts[:app_name],
      shard_id: opts[:shard_id],
      lease_owner: opts[:lease_owner]
    ]

    lease_opts =
      lease_opts
      |> optional_kw(:app_state_opts, Keyword.get(opts, :app_state_opts))
      |> optional_kw(:renew_interval, Keyword.get(opts, :lease_renew_interval))
      |> optional_kw(:lease_expiry, Keyword.get(opts, :lease_expiry))

    children = [
      {Lease, lease_opts},
      {Pipeline, pipeline_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start(supervisor, shard_info) do
    DynamicSupervisor.start_child(supervisor, {__MODULE__, shard_info})
  end

  def name(stream_name, shard_id) do
    result = Module.concat(__MODULE__, stream_name)
    Module.concat(result, shard_id)
  end
end