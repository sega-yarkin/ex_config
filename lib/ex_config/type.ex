defmodule ExConfig.Type do
  @callback __struct__(any) :: any
  @callback validators() :: Keyword.t(validator(any))
  @callback init(options :: Keyword.t) :: struct
  @callback default() :: any
  @callback handle(data :: any, opts :: struct) :: {:ok, any} | {:error, String.t}

  @type t() :: struct()

  defmacro __using__(_opts) do
    quote do
      @behaviour ExConfig.Type

      @impl ExConfig.Type
      def init(opts) when is_list(opts) do
        struct!(__MODULE__, opts)
      end

      @impl ExConfig.Type
      def validators, do: []

      @impl ExConfig.Type
      def default, do: nil

      defoverridable init: 1, validators: 0, default: 0
    end
  end

  alias ExConfig.Param.TypeOptionError, as: Err

  @type validator_result(t) :: {:ok, t} | :skip | :error
  @type validator(t) :: (any() -> validator_result(t))

  @spec validate_options(Keyword.t(validator(any)), Keyword.t(any))
        :: Keyword.t(any) | {:error, {name :: atom, value :: any}}
  def validate_options(validators, options) do
    Enum.reduce_while(
      validators,
      Keyword.new(),
      fn ({name, validator}, acc) ->
        case validator.(options[name]) do
          {:ok, value} -> {:cont, Keyword.put(acc, name, value)}
          :skip        -> {:cont, acc}
          :error       -> {:halt, {:error, {name, options[name]}}}
        end
      end
    )
  end

  @spec validate_options!(Keyword.t(validator(any)), Keyword.t(any), module)
        :: Keyword.t(any)
  def validate_options!(validators, options, type) do
    with {:error, {name, value}} <- validate_options(validators, options) do
      raise Err, type: type, name: name, value: value
    end
  end

  @spec validator_boolean(any) :: validator_result(boolean)
  def validator_boolean(nil), do: :skip
  def validator_boolean(val) when is_boolean(val), do: {:ok, val}
  def validator_boolean(_), do: :error
end
