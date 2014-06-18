#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Jazz.Decode do
  @spec it(String.t)            :: { :ok, term } | { :error, term }
  @spec it(String.t, Keyword.t) :: { :ok, term } | { :error, term }
  def it(string, options \\ []) when string |> is_binary do
    case Jazz.Parser.parse(string) do
      { :ok, parsed } ->
        { :ok, transform(parsed, options) }

      error ->
        error
    end
  end

  @spec it!(String.t)            :: term | no_return
  @spec it!(String.t, Keyword.t) :: term | no_return
  def it!(string, options \\ []) when string |> is_binary do
    Jazz.Parser.parse!(string) |> transform(options)
  end

  @spec transform(term) :: term
  @spec transform(term, Keyword.t) :: term
  def transform(parsed, options \\ [])

  def transform(parsed, []) do
    parsed
  end

  def transform(parsed, [keys: :atoms]) when parsed |> is_map do
    for { key, value } <- parsed, into: %{} do
      if value |> is_list or value |> is_map do
        value = transform(value, keys: :atoms)
      end

      { String.to_atom(key), value }
    end
  end

  def transform(parsed, [keys: :atoms]) when parsed |> is_list do
    for value <- parsed do
      if value |> is_list or value |> is_map do
        value = transform(value, keys: :atoms)
      end

      value
    end
  end

  def transform(parsed, [keys: :atoms!]) when parsed |> is_map do
    for { key, value } <- parsed, into: %{} do
      if value |> is_list or value |> is_map do
        value = transform(value, keys: :atoms!)
      end

      { String.to_existing_atom(key), value }
    end
  end

  def transform(parsed, [keys: :atoms!]) when parsed |> is_list do
    for value <- parsed do
      if value |> is_list or value |> is_map do
        value = transform(value, keys: :atoms)
      end

      value
    end
  end

  def transform(parsed, options) do
    keys = options[:keys]

    case options[:as] do
      as when as |> is_atom ->
        Jazz.Decoder.from_json(as.__struct__, parsed, options)

      [as] when as |> is_atom ->
        for parsed <- parsed do
          Jazz.Decoder.from_json(as.__struct__, parsed, options)
        end

      as when as |> is_list ->
        as = for { name, value } <- as do
          { to_string(name), value }
        end

        for { name, value } <- parsed, into: %{} do
          value = cond do
            spec = as |> List.keyfind(name, 0) ->
              { _name, spec } = spec

              transform(value, Keyword.put(options, :as, spec))

            keys && value |> is_list ->
              transform(value, keys: keys)

            true ->
              value
          end

          if keys do
            name = case keys do
              :atoms  -> String.to_atom(name)
              :atoms! -> String.to_existing_atom(name)
            end
          end

          { name, value }
        end
    end
  end
end

defprotocol Jazz.Decoder do
  @fallback_to_any true
  def from_json(new, parsed, options)
end

defimpl Jazz.Decoder, for: Any do
  def from_json(%{__struct__: _} = new, parsed, _options) do
    new |> Map.merge for { name, value } <- parsed, into: %{},
      do: { String.to_existing_atom(name), value }
  end
end
