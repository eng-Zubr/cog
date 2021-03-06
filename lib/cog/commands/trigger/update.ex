defmodule Cog.Commands.Trigger.Update do
  use Cog.Command.GenCommand.Base,
    bundle: Cog.Util.Misc.embedded_bundle,
    name: "trigger-update"

  alias Cog.Repository.Triggers
  require Cog.Commands.Helpers, as: Helpers

  @description "Update a pipeline trigger."

  @arguments "<name>"

  option "description", type: "string", short: "d", description: "Free text description of the trigger. Defaults to nil."
  option "enabled", type: "bool", short: "e", description: "Whether the trigger will be enabled or not"
  option "name", type: "string", short: "n", description: "the new name of the trigger"
  option "pipeline", type: "string", short: "p", description: "The new text of the pipeline for this trigger"
  option "timeout-sec", type: "int", short: "t", description: "Amount of time Cog will wait for execution to finish"
  option "as-user", type: "string", short: "u", description: "The Cog username the trigger will execute as."

  @examples """
  trigger update my-trigger -d "A friendly greeting"
  """

  @output_description "Returns the json representation of the trigger that was just updated."

  @output_example """
  [
    {
      "timeout_sec": 30,
      "pipeline": "echo fizbaz",
      "name": "foo",
      "invocation_url": "http://localhost:4001/v1/triggers/00000000-0000-0000-0000-000000000000",
      "id": "00000000-0000-0000-0000-000000000000",
      "enabled": false,
      "description": null,
      "as_user": null
    }
  ]
  """

  permission "manage_triggers"

  rule "when command is #{Cog.Util.Misc.embedded_bundle}:trigger-update must have #{Cog.Util.Misc.embedded_bundle}:manage_triggers"

  def handle_message(req, state) do
    result = with {:ok, args} <- Helpers.get_args(req.args, 1) do
      update(req, args)
    end

    case result do
      {:ok, data} ->
        {:reply, req.reply_to, "trigger-update", Cog.Command.Trigger.Helpers.convert(data), state}
      {:error, error} ->
        {:error, req.reply_to, Helpers.error(error), state}
    end
  end

  # This is broken out into a public function because it is accessed in the enable and disable command modules
  def update(req, [name]) do
    case Triggers.by_name(name) do
      {:ok, trigger} ->
        params = Cog.Command.Trigger.Helpers.normalize_params(req.options)
        case Triggers.update(trigger, params) do
          {:ok, trigger} ->
            {:ok, trigger}
          {:error, error} ->
            {:error, {:trigger_invalid, error}}
        end
      {:error, :not_found} ->
        {:error, {:resource_not_found, "trigger", name}}
    end
  end

end
