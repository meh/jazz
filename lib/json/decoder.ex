#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule JSON.Decode do
  @spec it(String.t)            :: { :ok, term } | { :error, term }
  @spec it(String.t, Keyword.t) :: { :ok, term } | { :error, term }
  def it(string, options \\ []) when string |> is_binary do
    case JSON.Parser.parse(string) do
      { :ok, parsed } ->
        { :ok, transform(parsed, options) }

      error ->
        error
    end
  end

  @spec it!(String.t)            :: term | no_return
  @spec it!(String.t, Keyword.t) :: term | no_return
  def it!(string, options \\ []) when string |> is_binary do
    JSON.Parser.parse!(string) |> transform(options)
  end

  @spec transform(term) :: term
  @spec transform(term, Keyword.t) :: term
  def transform(parsed, options \\ [])

  def transform(parsed, [keys: :atoms]) when parsed |> is_list do
    Enum.map parsed, fn
      elem when elem |> is_list ->
        transform(elem, keys: :atoms)

      { name, value } when value |> is_list ->
        { binary_to_atom(name), transform(value, keys: :atoms) }

      { name, value } ->
        { binary_to_atom(name), value }

      value ->
        value
    end
  end

  def transform(parsed, [keys: :atoms!]) when parsed |> is_list do
    Enum.map parsed, fn
      elem when elem |> is_list ->
        transform(elem, keys: :atoms!)

      { name, value } when is_list(value) ->
        { binary_to_existing_atom(name), transform(value, keys: :atoms!) }

      { name, value } ->
        { binary_to_existing_atom(name), value }

      value ->
        value
    end
  end

  def transform(parsed, []) do
    parsed
  end

  def transform(parsed, options) do
    keys = options[:keys]

    case Keyword.fetch!(options, :as) do
      as when as |> is_atom ->
        JSON.Decoder.from_json({ as, parsed, options })

      [as] when as |> is_atom ->
        Enum.map parsed, fn parsed ->
          JSON.Decoder.from_json({ as, parsed, options })
        end

      as when as |> is_list ->
        as = Enum.map as, fn { name, value } ->
          { to_string(name), value }
        end

        Enum.map parsed, fn { name, value } ->
          value = cond do
            spec = as[name] ->
              transform(value, Keyword.put(options, :as, spec))

            keys && value |> is_list ->
              transform(value, keys: keys)

            true ->
              value
          end

          if keys do
            name = case keys do
              :atoms  -> binary_to_atom(name)
              :atoms! -> binary_to_existing_atom(name)
            end
          end

          { name, value }
        end
    end
  end
end

defprotocol JSON.Decoder do
  def from_json(data)
end

defimpl JSON.Decoder, for: Tuple do
  def from_json({ name, parsed, _ }) do
    name.new(parsed)
  end
end

defimpl JSON.Decoder, for: HashDict do
  def from_json({ _, parsed, _ }) do
    HashDict.new(parsed)
  end
end

defimpl JSON.Decoder, for: HashSet do
  def from_json({ _, parsed, _ }) do
    HashSet.new(parsed)
  end
end
