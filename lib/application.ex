# SPDX-FileCopyrightText: 2023 ash_events contributors <https://github.com/ash-project/ash_events/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshEvents.Application do
  @moduledoc false

  use Application

  # The manual action wrappers are only ever referenced as data in each
  # tracked action's `manual` field (e.g. `{AshEvents.DestroyActionWrapper,
  # opts}`), so they are not loaded until an action is actually run. Ash's bulk
  # pipeline decides whether to use the batch callbacks with
  # `function_exported?(mod, :bulk_update, 3)` / `bulk_destroy, 3)`, and
  # `function_exported?/3` returns `false` for a module that has not been
  # loaded yet. That makes Ash take the single-record fallback path for the
  # first bulk operation, which mismatches the context key for soft-delete
  # bulk destroys (`:bulk_destroy` vs `:bulk_update`) and crashes with a
  # `BadMapError`.
  #
  # Eagerly loading the wrappers on application start guarantees they are
  # loaded before Ash introspects them.
  @wrappers [
    AshEvents.CreateActionWrapper,
    AshEvents.UpdateActionWrapper,
    AshEvents.DestroyActionWrapper
  ]

  @impl true
  def start(_type, _args) do
    ensure_wrappers_loaded()

    Supervisor.start_link([], strategy: :one_for_one, name: AshEvents.Supervisor)
  end

  @doc false
  def ensure_wrappers_loaded() do
    Enum.each(@wrappers, &Code.ensure_loaded/1)
  end
end
