defmodule ExConfig.Type do
  @callback __struct__(any) :: any
  @callback init(options :: keyword) :: struct
  @callback handle(data :: any, opts :: struct) :: {:ok, any} | {:error, String.t}
end


defmodule ExConfig.Type.Raw do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _), do: {:ok, data}
end


defmodule ExConfig.Type.Number do
  @behaviour ExConfig.Type
  alias ExConfig.Param

  @type range() :: %Range{}
                 | {min :: number(), max :: number()}
                 | {:gt | :ge | :lt | :le, number()}

  defstruct [:range]
  @type t() :: %__MODULE__{
    range: nil | range(),
  }

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:range]))
  end

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse/1,
      &maybe_check_range(&1, opts),
    ])
  end

  defp parse(data) when is_list(data), do: parse(to_string(data))
  defp parse(data) when is_binary(data) do
    case Float.parse(data) do
      {value, _} -> {:ok, value}
      :error     -> {:error, "Cannot parse '#{inspect(data)}' as a number"}
    end
  end
  defp parse(data), do: {:error, "Cannot parse '#{inspect(data)}' as a number"}


  def maybe_check_range(value, %{range: range}) when range != nil do
    range = maybe_transform_range(range)
    if in_range?(value, range),
      do: {:ok, value},
    else: {:error, "'#{inspect(value)}' is out of range #{range_to_string(range)}"}
  end
  def maybe_check_range(value, _), do: {:ok, value}

  defp maybe_transform_range(%Range{first: first, last: last}),
    do: if first > last, do: {last, first}, else: {first, last}
  defp maybe_transform_range(range),
    do: range

  defp in_range?(value, {:gt, num}), do: value > num
  defp in_range?(value, {:ge, num}), do: value >= num
  defp in_range?(value, {:lt, num}), do: value < num
  defp in_range?(value, {:le, num}), do: value <= num
  defp in_range?(value, {min, max}), do: min <= value and value <= max

  defp range_to_string({:gt, num}), do: "(#{num}, inf)"
  defp range_to_string({:ge, num}), do: "[#{num}, inf)"
  defp range_to_string({:lt, num}), do: "(inf, #{num})"
  defp range_to_string({:le, num}), do: "(inf, #{num}]"
  defp range_to_string({min, max}), do: "[#{min}, #{max}]"

end


defmodule ExConfig.Type.Integer do
  @behaviour ExConfig.Type
  alias ExConfig.Param
  alias ExConfig.Type.Number

  defstruct base: 10,
            range: nil
  @type t() :: %__MODULE__{
    base: 2..36,
    range: nil | Number.range(),
  }

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:base, :range]))
  end

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse(&1, opts),
      &Number.maybe_check_range(&1, opts),
    ])
  end

  defp parse(data, opts) when is_list(data), do: parse(to_string(data), opts)
  defp parse(data, opts) when is_binary(data) do
    case Integer.parse(data, opts.base) do
      {value, _} -> {:ok, value}
      :error     -> {:error, "Cannot parse '#{inspect(data)}' as an integer"}
    end
  end
  defp parse(data, _), do: {:error, "Cannot parse '#{inspect(data)}' as an integer"}
end


defmodule ExConfig.Type.Boolean do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _opts), do: do_handle(data)


  defp do_handle(data) when is_boolean(data), do: {:ok, data}

  defp do_handle(data) when is_binary(data) do
    case String.downcase(data) do
      "true"  -> {:ok, true}
      "false" -> {:ok, false}
      _       -> {:error, "Cannot handle '#{inspect(data)}' as a boolean"}
    end
  end

  defp do_handle(data) when is_list(data),
    do: do_handle(to_string(data))

  defp do_handle(data),
    do: {:error, "Cannot handle '#{inspect(data)}' as a boolean"}

end


defmodule ExConfig.Type.String do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _opts) when is_binary(data), do: {:ok, data}

  def handle(data, opts) when is_list(data),
    do: handle(to_string(data), opts)

  def handle(data, _opts),
    do: {:error, "Cannot handle '#{inspect(data)}' as a string"}

end


defmodule ExConfig.Type.Enum do
  @behaviour ExConfig.Type

  @enforce_keys [:values]
  defstruct [:values]
  @type t() :: %__MODULE__{
    values: nonempty_list(atom()),
  }

  @impl true
  def init(opts) do
    enum = struct!(__MODULE__, Keyword.take(opts, [:values]))
    unless length(enum.values) > 0 do
      raise ArgumentError, "Enum values cannot be empty"
    end
    enum
  end

  @impl true
  def handle(data, %{values: values}) when byte_size(data) > 0 do
    as_atom = String.to_atom(data)
    if as_atom in values,
      do: {:ok, as_atom},
    else: {:error, "Wrong enum value '#{inspect(as_atom)}', only accept #{inspect(values)}"}
  end

  def handle(data, _), do: {:error, "Cannot handle '#{inspect(data)}' as an enum"}

end


defmodule ExConfig.Type.ModuleName do
  @behaviour ExConfig.Type

  defstruct should_exist?: true

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:should_exist?]))
  end

  @impl true
  def handle(data, opts) do
    with {:ok, name} <- maybe_convert(data),
         :ok         <- valid?(name, opts),
      do: {:ok, name}
  end


  defp maybe_convert(name) when is_atom(name),
    do: {:ok, name}

  defp maybe_convert(name) when byte_size(name) > 0 do
    name =
      case name do
        <<":"      , _ :: binary>> -> name # Erlang module
        <<"Elixir.", _ :: binary>> -> name # Elixir one
        _ -> "Elixir.#{name}" # By default Elixir module without prefix
      end
    {:ok, String.to_atom(name)}
  end

  defp maybe_convert(name) when is_list(name),
    do: maybe_convert(to_string(name))

  defp maybe_convert(name),
    do: {:error, "Cannot convert #{inspect(name)} to module name"}


  defp valid?(module, %{should_exist?: true}) do
    try do
      apply(module, :module_info, [:module])
      :ok
    rescue
      _ -> {:error, "Module #{module} is not available"}
    end
  end
  defp valid?(_module, _), do: :ok
end
