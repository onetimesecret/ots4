defmodule OneTimeWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Info" flash={@flash} />
      <.flash kind={:error} title="Error" flash={@flash} />
    </div>
    """
  end

  @doc """
  Renders a single flash notice.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-4 right-4 z-50 w-96 rounded-lg p-4 shadow-lg",
        @kind == :info && "bg-blue-50 border border-blue-200",
        @kind == :error && "bg-red-50 border border-red-200"
      ]}
      {@rest}
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            :if={@kind == :info}
            class="h-5 w-5 text-blue-400"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
              clip-rule="evenodd"
            />
          </svg>
          <svg
            :if={@kind == :error}
            class="h-5 w-5 text-red-400"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <div class="ml-3 flex-1">
          <p :if={@title} class={[
            "text-sm font-medium",
            @kind == :info && "text-blue-800",
            @kind == :error && "text-red-800"
          ]}>
            <%= @title %>
          </p>
          <p class={[
            "text-sm",
            @kind == :info && "text-blue-700",
            @kind == :error && "text-red-700"
          ]}>
            <%= msg %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @doc """
  Hides the flash group.
  """
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm",
        "text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkboxes"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-1 block w-full rounded-md border-gray-300 shadow-sm",
          "focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
          @errors != [] && "border-red-300 focus:border-red-500 focus:ring-red-500"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-1 block w-full rounded-md border-gray-300 shadow-sm",
          "focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
          @errors != [] && "border-red-300 focus:border-red-500 focus:ring-red-500"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-medium text-gray-700">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-red-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  defp translate_error(msg), do: msg

  @doc """
  Renders a datetime with timezone information.

  By default shows UTC, but adds data attributes for client-side
  JavaScript to convert to the user's local timezone.

  ## Examples

      <.datetime value={@secret.expires_at} />
      <.datetime value={@secret.expires_at} format="short" />

  """
  attr :value, :any, required: true, doc: "the datetime value (DateTime or NaiveDateTime)"
  attr :format, :string, default: "long", values: ["short", "long", "relative"]
  attr :class, :string, default: ""

  def datetime(assigns) do
    ~H"""
    <time
      datetime={to_iso8601(@value)}
      phx-hook="LocalTime"
      data-format={@format}
      id={"time-" <> to_iso8601(@value)}
      class={@class}
      title={Calendar.strftime(@value, "%B %d, %Y at %I:%M:%S %p UTC")}
    >
      <%= format_time(@value, @format) %>
    </time>
    """
  end

  defp to_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp to_iso8601(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)

  defp format_time(value, "short") do
    Calendar.strftime(value, "%b %d, %Y %I:%M %p")
  end

  defp format_time(value, "relative") do
    now = DateTime.utc_now()
    diff = DateTime.diff(value, now)

    cond do
      diff < 60 -> "in #{diff} seconds"
      diff < 3600 -> "in #{div(diff, 60)} minutes"
      diff < 86400 -> "in #{div(diff, 3600)} hours"
      diff < 604_800 -> "in #{div(diff, 86400)} days"
      true -> Calendar.strftime(value, "%b %d, %Y")
    end
  end

  defp format_time(value, _format) do
    Calendar.strftime(value, "%B %d, %Y at %I:%M %p")
  end
end
