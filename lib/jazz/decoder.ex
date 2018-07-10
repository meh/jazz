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
      value = if value |> is_list or value |> is_map do
        transform(value, keys: :atoms)
      else
        value
      end

      { String.to_atom(key), value }
    end
  end

  def transform(parsed, [keys: :atoms]) when parsed |> is_list do
    for value <- parsed do
      if value |> is_list or value |> is_map do
        transform(value, keys: :atoms)
      else
        value
      end
    end
  end

  def transform(parsed, [keys: :atoms!]) when parsed |> is_map do
    for { key, value } <- parsed, into: %{} do
      value = if value |> is_list or value |> is_map do
        transform(value, keys: :atoms!)
      else
        value
      end

      { String.to_existing_atom(key), value }
    end
  end

  def transform(parsed, [keys: :atoms!]) when parsed |> is_list do
    for value <- parsed do
      if value |> is_list or value |> is_map do
        transform(value, keys: :atoms)
      else
        value
      end
    end
  end

  def transform(parsed, options) do
    keys = options[:keys]

    case options[:as] do
      as when as |> is_atom ->
        Jazz.Decoder.decode(as.__struct__, parsed, options)

      [as] when as |> is_atom ->
        for parsed <- parsed do
          Jazz.Decoder.decode(as.__struct__, parsed, options)
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

          name = if keys do
            case keys do
              :atoms  -> String.to_atom(name)
              :atoms! -> String.to_existing_atom(name)
            end
          else
            name
          end

          { name, value }
        end
    end
  end
end

defprotocol Jazz.Decoder do
  @fallback_to_any true
  def decode(new, parsed, options)
end

defimpl Jazz.Decoder, for: Any do
  def decode(%{__struct__: module} = new, parsed, _options) do
    for { name, old } <- Map.delete(new, :__struct__), into: %{} do
      if value = parsed[name |> to_string] do
        { name, value }
      else
        { name, old }
      end
    end |> Map.put(:__struct__, module)
  end
end
