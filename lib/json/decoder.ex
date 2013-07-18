#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule JSON.Decode do
  def it(string, options // [])

  def it(string, options) when is_binary(string) do
    binary_to_list(string) |> it(options)
  end

  def it(string, options) do
    case :json_lexer.string(string) do
      { :ok, lexed, _ } ->
        case :json_parser.parse(lexed) do
          { :ok, parsed } ->
            { :ok, case options[:as] do
              nil ->
                parsed

              [as] ->
                Enum.map parsed, fn parsed ->
                  JSON.Decoder.from_json({ as, parsed, options })
                end

              as ->
                JSON.Decoder.from_json({ as, parsed, options })
            end }

          { :error, _ } = e ->
            e
        end

      { :error, _ } = e ->
        e
    end
  end
end

defprotocol JSON.Decoder do
  def from_json(data)
end

defimpl JSON.Decoder, for: Tuple do
  def from_json({ name, parsed, _ }) do
    fields = name.__record__(:fields)

    [name | Enum.map(fields, fn { name, default } ->
      Dict.get(parsed, atom_to_binary(name), default)
    end)] |> list_to_tuple
  end
end

defimpl JSON.Decoder, for: HashDict do
  def from_json({ _, parsed, _ }) do
    HashDict.new(parsed)
  end
end
