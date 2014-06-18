#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Jazz.Encode do
  @spec it(term, Keyword.t) :: String.t
  def it(data, options \\ []) do
    case Jazz.Encoder.to_json(data, options) do
      { encode } when encode |> is_binary ->
        { :ok, encode }

      value ->
        it(value, options)
    end
  end
end

defprotocol Jazz.Encoder do
  @fallback_to_any true

  def to_json(self, options)
end

defmodule Jazz.Pretty do
  defmacro __using__(_opts) do
    quote do
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
    end
  end
end

defimpl Jazz.Encoder, for: List do
  use Jazz.Pretty

  def to_json([], _) do
    { "[]" }
  end

  def to_json(self, options) do
    { encode(self, options, options[:pretty]) }
  end

  defp encode(self, options, pretty) when pretty == true do
    [first | rest] = Enum.map self, fn element ->
      [", ", Jazz.encode!(element, options)]
    end

    ["[", tl(first), rest, "]"] |> IO.iodata_to_binary
  end

  defp encode(self, options, pretty) when pretty == false or pretty == nil do
    [first | rest] = Enum.map self, fn element ->
      [",", Jazz.encode!(element, options)]
    end

    ["[", tl(first), rest, "]"] |> IO.iodata_to_binary
  end
end

defimpl Jazz.Encoder, for: Map do
  use Jazz.Pretty

  def to_json(self, _) when map_size(self) == 0 do
    { "{}" }
  end

  def to_json(self, options) do
    { encode(self, options, options[:pretty]) }
  end

  defp encode(self, options, pretty) when pretty == true do
    offset = offset(options)
    indent = indentation(options)

    [first | rest] = Enum.map self, fn { name, value } ->
      name  = Jazz.encode!(to_string(name))
      value = Jazz.encode!(value, offset(options, indent))

      [",\n", spaces(indent), name, ": ", value]
    end

    ["{\n", tl(first), rest, "\n", spaces(offset), "}"] |> IO.iodata_to_binary
  end

  defp encode(self, options, pretty) when pretty == false or pretty == nil do
    [first | rest] = Enum.map self, fn { name, value } ->
      [",", Jazz.encode!(to_string(name)), ":", Jazz.encode!(value, options)]
    end

    ["{", tl(first), rest, "}"] |> IO.iodata_to_binary
  end
end

defimpl Jazz.Encoder, for: Any do
  def to_json(%{__struct__: _} = self, options) do
    Jazz.Encoder.Map.to_json(self |> Map.delete(:__struct__), options)
  end
end

defimpl Jazz.Encoder, for: Atom do
  def to_json(true, _) do
    { "true" }
  end

  def to_json(false, _) do
    { "false" }
  end

  def to_json(nil, _) do
    { "null" }
  end
end

defimpl Jazz.Encoder, for: BitString do
  def to_json(self, options) do
    mode = options[:mode]

    unless mode do
      mode = case options[:escape] do
        nil      -> :unicode
        :unicode -> :ascii
      end
    end

    { [?", encode(self, mode), ?"] |> List.to_string }
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
    ["\\u", Integer.to_char_list(char, 16) | encode(rest, :javascript)]
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
    ["\\u", pad(Integer.to_char_list(char, 16)) | encode(rest, mode)]
  end

  defp encode(<< char :: utf8, rest :: binary >>, mode) when char in 0x010000 .. 0x10FFFF do
    use Bitwise

    point = char - 0x10000

    ["\\u", pad(Integer.to_char_list(0xD800 + (point >>> 10), 16)),
     "\\u", pad(Integer.to_char_list(0xDC00 + (point &&& 0x003FF), 16)) | encode(rest, mode)]
  end

  defp encode("", _) do
    []
  end

  defp pad([_] = s),          do: [?0, ?0, ?0 | s]
  defp pad([_, _] = s),       do: [?0, ?0 | s]
  defp pad([_, _, _] = s),    do: [?0 | s]
  defp pad([_, _, _, _] = s), do: s
end

defimpl Jazz.Encoder, for: [Integer, Float] do
  def to_json(self, _) do
    { to_string(self) }
  end
end
