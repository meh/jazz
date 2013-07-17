#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule JSON.Encode do
  def it(data, options // []) do
    encode = JSON.Encoder.to_json(data, options)

    cond do
      is_list(encode) ->
        JSON.Encoder.to_json(encode, options)

      is_binary(encode) ->
        encode
    end
  end
end

defprotocol JSON.Encoder do
  def to_json(self, options)
end

defimpl JSON.Encoder, for: List do
  def object?([{ head, _ } | _]) when not is_binary(head) and not is_atom(head) do
    false
  end

  def object?([{ _, _ } | rest]) do
    object?(rest)
  end

  def object?([]) do
    true
  end

  def object?(_) do
    false
  end

  def to_json(self, options) do
    if object?(self) do
      "{" <> (Enum.map(self, fn { name, value } ->
        inspect(atom_to_binary(name)) <> ":" <> JSON.encode(value, options)
      end) |> Enum.join(",")) <> "}"
    else
      "[" <> (Enum.map(self, JSON.encode(&1, options)) |> Enum.join(",")) <> "]"
    end
  end
end

defimpl JSON.Encoder, for: Atom do
  def to_json(true, _) do
    "true"
  end

  def to_json(false, _) do
    "false"
  end

  def to_json(nil, _) do
    "null"
  end

  def to_json(self, _) do
    atom_to_binary(self) |> inspect
  end
end

defimpl JSON.Encoder, for: BitString do
  def to_json(self, _) do
    inspect(self)
  end
end

defimpl JSON.Encoder, for: Number do
  def to_json(self, _) do
    to_binary(self)
  end
end

defimpl JSON.Encoder, for: Tuple do
  def to_json(self, options) do
    name   = elem(self, 0)
    fields = name.__record__(:fields)

    Enum.with_index(fields) |> Enum.map fn { { name, _ }, index } ->
      { name, elem(self, index + 1) }
    end
  end
end

defimpl JSON.Encoder, for: HashDict do
  def to_json(self, options) do
    HashDict.to_list(self)
  end
end
