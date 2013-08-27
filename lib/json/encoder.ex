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
        { :ok, JSON.Encoder.to_json(encode, options) }

      is_binary(encode) ->
        { :ok, encode }
    end
  end
end

defprotocol JSON.Encoder do
  def to_json(self, options)
end

defimpl JSON.Encoder, for: List do
  defp offset(options) do
    Keyword.get(options, :offset, 0)
  end

  defp offset(options, value) do
    Keyword.put(options, :offset, value)
  end

  defp indentation(options) do
    Keyword.get(options, :indent, 4) + Keyword.get(options, :offset, 0)
  end

  def spaces(number) do
    String.duplicate(" ", number)
  end

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

  def to_json([], _) do
    "[]"
  end

  def to_json(self, options) do
    if object?(self) do
      encode_object(self, options, options[:pretty])
    else
      encode_array(self, options, options[:pretty])
    end
  end

  defp encode_object(self, options, pretty) when pretty == true do
    offset = offset(options)
    indent = indentation(options)

    [first | rest] = Enum.map self, fn { name, value } ->
      name  = JSON.encode!(to_binary(name))
      value = JSON.encode!(value, offset(options, indent))

      [",\n", spaces(indent), name, ": ", value]
    end

    ["{\n", tl(first), rest, "\n", spaces(offset), "}"] |> iolist_to_binary
  end

  defp encode_object(self, options, pretty) when pretty == false or pretty == nil do
    [first | rest] = Enum.map self, fn { name, value } ->
      [",", JSON.encode!(to_binary(name)), ":", JSON.encode!(value, options)]
    end

    ["{", tl(first), rest, "}"] |> iolist_to_binary
  end

  defp encode_array(self, options, pretty) when pretty == true do
    [first | rest] = Enum.map self, fn element ->
      [", ", JSON.encode!(element, options)]
    end

    ["[", tl(first), rest, "]"] |> iolist_to_binary
  end

  defp encode_array(self, options, pretty) when pretty == false or pretty == nil do
    [first | rest] = Enum.map self, fn element ->
      [",", JSON.encode!(element, options)]
    end

    ["[", tl(first), rest, "]"] |> iolist_to_binary
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
  def to_json(self, options) do
    mode = case options[:escape] do
      nil      -> :unicode
      :unicode -> :ascii
    end

    [?", encode(self, mode), ?"] |> String.from_char_list!
  end

  defp encode(<< char :: utf8, rest :: binary >>, mode) when char in 0x20 .. 0x21 or
                                                             char in 0x23 .. 0x5B or
                                                             char in 0x5D .. 0x7E do
    [char | encode(rest, mode)]
  end

  @escape [?", ?\\, { ?\b, ?b }, { ?\f, ?f }, { ?\n, ?n }, { ?\r, ?r }, { ?\t, ?t }]
  Enum.each @escape, fn
    { match, insert } ->
      defp encode(<< unquote(match) :: utf8, rest :: binary >>, mode) do
        [?\\, unquote(insert) | encode(rest, mode)]
      end

    match ->
      defp encode(<< unquote(match) :: utf8, rest :: binary >>, mode) do
        [?\\, unquote(match) | encode(rest, mode)]
      end
  end

  defp encode(<< char :: utf8, rest :: binary >>, :unicode) when char in 0x0000   .. 0xFFFF or
                                                                 char in 0x010000 .. 0x10FFFF do
    [char | encode(rest, :unicode)]
  end

  defp encode(<< char :: utf8, rest :: binary >>, mode) when char in 0x0000 .. 0xFFFF do
    ["\\u", pad(integer_to_list(char, 16)) | encode(rest, mode)]
  end

  defp encode(<< char :: utf8, rest :: binary >>, mode) when char in 0x010000 .. 0x10FFFF do
    use Bitwise

    point = char - 0x10000

    ["\\u", pad(integer_to_list(0xD800 + (point >>> 10), 16)),
     "\\u", pad(integer_to_list(0xDC00 + (point &&& 0x003FF), 16)) | encode(rest, mode)]
  end

  defp encode("", _) do
    []
  end

  defp pad([_] = s),          do: [?0, ?0, ?0 | s]
  defp pad([_, _] = s),       do: [?0, ?0 | s]
  defp pad([_, _, _] = s),    do: [?0 | s]
  defp pad([_, _, _, _] = s), do: s
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
