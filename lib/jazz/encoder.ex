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
    case Jazz.Encoder.encode(data, options) do
      { encode } when encode |> is_binary ->
        { :ok, encode }

      %{__struct__: _} ->
        { :error, :recursive }

      value ->
        it(value, options)
    end
  end
end

defprotocol Jazz.Encoder do
  @fallback_to_any true

  def encode(self, options)
end

defmodule Jazz.Pretty do
  defmacro __using__(_opts) do
    quote do
      @compile { :inline, offset: 1, offset: 2, indentation: 1, spaces: 1 }

      def offset(options) do
        Keyword.get(options, :offset, 0)
      end

      def offset(options, value) do
        Keyword.put(options, :offset, value)
      end

      def indentation(options) do
        Keyword.get(options, :indent, 4) + Keyword.get(options, :offset, 0)
      end

      def spaces(number) do
        String.duplicate(" ", number)
      end
    end
  end
end

defimpl Jazz.Encoder, for: List do
  use Jazz.Pretty

  def encode([], _) do
    { "[]" }
  end

  def encode(self, options) do
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

  def encode(self, _) when map_size(self) == 0 do
    { "{}" }
  end

  def encode(self, options) do
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
  def encode(%{__struct__: _} = self, options) do
    Jazz.Encoder.Map.encode(self |> Map.delete(:__struct__), options)
  end
end

defimpl Jazz.Encoder, for: Atom do
  def encode(true, _) do
    { "true" }
  end

  def encode(false, _) do
    { "false" }
  end

  def encode(nil, _) do
    { "null" }
  end
end

defimpl Jazz.Encoder, for: BitString do
  def encode(self, options) do
    mode = unless options[:mode] do
      case options[:escape] do
        nil      -> :unicode
        :unicode -> :ascii
      end
    else
      options[:mode]
    end

    { [?", it(self, mode), ?"] |> List.to_string }
  end

  defp it(<< char :: utf8, rest :: binary >>, mode) when char in 0x20 .. 0x21 or
                                                             char in 0x23 .. 0x5B or
                                                             char in 0x5D .. 0x7E do
    [char | it(rest, mode)]
  end

  @escape [?", ?\\, { ?\b, ?b }, { ?\f, ?f }, { ?\n, ?n }, { ?\r, ?r }, { ?\t, ?t }]
  Enum.each @escape, fn
    { match, insert } ->
      defp it(<< unquote(match) :: utf8, rest :: binary >>, mode) do
        [?\\, unquote(insert) | it(rest, mode)]
      end

    match ->
      defp it(<< unquote(match) :: utf8, rest :: binary >>, mode) do
        [?\\, unquote(match) | it(rest, mode)]
      end
  end

  defp it(<< char :: utf8, rest :: binary >>, :javascript) when char in [0x2028, 0x2029] do
    ["\\u", Integer.to_charlist(char, 16) | it(rest, :javascript)]
  end

  defp it(<< char :: utf8, rest :: binary >>, :javascript) when char in 0x0000   .. 0xFFFF or
                                                                    char in 0x010000 .. 0x10FFFF do
    [char | it(rest, :javascript)]
  end

  defp it(<< char :: utf8, rest :: binary >>, :unicode) when char in 0x0000   .. 0xFFFF or
                                                                 char in 0x010000 .. 0x10FFFF do
    [char | it(rest, :unicode)]
  end

  defp it(<< char :: utf8, rest :: binary >>, mode) when char in 0x0000 .. 0xFFFF do
    ["\\u", pad(Integer.to_charlist(char, 16)) | it(rest, mode)]
  end

  defp it(<< char :: utf8, rest :: binary >>, mode) when char in 0x010000 .. 0x10FFFF do
    use Bitwise

    point = char - 0x10000

    ["\\u", pad(Integer.to_charlist(0xD800 + (point >>> 10), 16)),
     "\\u", pad(Integer.to_charlist(0xDC00 + (point &&& 0x003FF), 16)) | it(rest, mode)]
  end

  defp it("", _) do
    []
  end

  defp pad([_] = s),          do: [?0, ?0, ?0 | s]
  defp pad([_, _] = s),       do: [?0, ?0 | s]
  defp pad([_, _, _] = s),    do: [?0 | s]
  defp pad([_, _, _, _] = s), do: s
end

defimpl Jazz.Encoder, for: [Integer, Float] do
  def encode(self, _) do
    { to_string(self) }
  end
end
