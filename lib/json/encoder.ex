#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule JSON.Encode do
  @spec it(term, Keyword.t) :: { :ok, String.t }
  def it(data, options \\ []) do
    case JSON.Encoder.to_json(data, options) do
      { encode } when encode |> is_binary ->
        { :ok, encode }

      value ->
        it(value, options)
    end
  end
end

defprotocol JSON.Encoder do
  def to_json(self, options)
end

defimpl JSON.Encoder, for: List do
  @compile { :inline, offset: 1, offset: 2, indentation: 1, spaces: 1 }

  defp offset(options) do
    Keyword.get(options, :offset, 0)
  end

  defp offset(options, value) do
    Keyword.put(options, :offset, value)
  end

  defp indentation(options) do
    Keyword.get(options, :indent, 4) + Keyword.get(options, :offset, 0)
  end

  defp spaces(number) do
    String.duplicate(" ", number)
  end

  defp object?([{ head, _ } | _]) when not is_binary(head) and not is_atom(head) do
    false
  end

  defp object?([{ _, _ } | rest]) do
    object?(rest)
  end

  defp object?([]) do
    true
  end

  defp object?(_) do
    false
  end

  def to_json([], _) do
    { "[]" }
  end

  def to_json(self, options) do
    { if object?(self) do
      encode_object(self, options, options[:pretty])
    else
      encode_array(self, options, options[:pretty])
    end }
  end

  defp encode_object(self, options, pretty) when pretty == true do
    offset = offset(options)
    indent = indentation(options)

    [first | rest] = Enum.map self, fn { name, value } ->
      name  = JSON.encode!(to_string(name))
      value = JSON.encode!(value, offset(options, indent))

      [",\n", spaces(indent), name, ": ", value]
    end

    ["{\n", tl(first), rest, "\n", spaces(offset), "}"] |> iolist_to_binary
  end

  defp encode_object(self, options, pretty) when pretty == false or pretty == nil do
    [first | rest] = Enum.map self, fn { name, value } ->
      [",", JSON.encode!(to_string(name)), ":", JSON.encode!(value, options)]
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
    { "true" }
  end

  def to_json(false, _) do
    { "false" }
  end

  def to_json(nil, _) do
    { "null" }
  end

  def to_json(self, _) do
    atom_to_binary(self)
  end
end

defimpl JSON.Encoder, for: BitString do
  def to_json(self, options) do
    mode = options[:mode]

    unless mode do
      mode = case options[:escape] do
        nil      -> :unicode
        :unicode -> :ascii
      end
    end

    { [?", encode(self, mode), ?"] |> String.from_char_list! }
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

  defp encode(<< char :: utf8, rest :: binary >>, :javascript) when char in [0x2028, 0x2029] do
    ["\\u", integer_to_list(char, 16) | encode(rest, :javascript)]
  end

  defp encode(<< char :: utf8, rest :: binary >>, :javascript) when char in 0x0000   .. 0xFFFF or
                                                                    char in 0x010000 .. 0x10FFFF do
    [char | encode(rest, :javascript)]
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

defimpl JSON.Encoder, for: [Integer, Float] do
  def to_json(self, _) do
    { to_string(self) }
  end
end

defimpl JSON.Encoder, for: Tuple do
  def to_json(self, _options) do
    self.to_keywords
  end
end

defimpl JSON.Encoder, for: HashDict do
  def to_json(self, _options) do
    HashDict.to_list(self)
  end
end

defimpl JSON.Encoder, for: HashSet do
  def to_json(self, _options) do
    HashSet.to_list(self)
  end
end
