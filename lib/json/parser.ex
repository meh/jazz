# The MIT License (MIT)
#
# Copyright (c) 2013 Andrew Hodges
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

defmodule JSON.Parser do
  import Kernel, except: [is_even: 1]

  use Bitwise

  @compile :native

  defmacrop after_quote(bin) do
    quote do: << ?\", unquote(bin) :: binary >>
  end

  defmacrop is_digit(char) do
    quote do: unquote(char) in ?0..?9
  end

  defmacrop is_even(int) do
    quote do: band(unquote(int), 1) === 0
  end

  defmacrop is_whitespace(char) do
    quote do: unquote(char) in ' \t\n\r'
  end

  def parse(bin) do
    try do
      { :ok, value(bin) |> elem(0) }
    catch
      :partial ->
        { :error, :partial }

      :invalid ->
        { :error, :invalid }
    end
  end

  defp after_pair("," <> rest, obj), do: members(rest, obj)
  defp after_pair("}" <> rest, obj), do: { leave_object(obj), rest }
  defp after_pair(<< ws, rest :: binary >>, obj) when is_whitespace(ws) do
    whitespace(rest) |> after_pair(obj)
  end

  defp after_element("," <> rest, arr), do: elements(rest, arr)
  defp after_element("]" <> rest, arr), do: { leave_array(arr), rest }
  defp after_element(<< ws, rest :: binary >>, arr) when is_whitespace(ws) do
    whitespace(rest) |> after_element(arr)
  end

  Enum.each Stream.concat([0x20..0x21, 0x23..0x5B, 0x5D..0x7E]), fn
    char ->
      defp chars(<< unquote(char), rest :: binary >>, iolist) do
        chars(rest, [iolist, unquote(char)])
      end
  end

  defp chars(<< char :: utf8, rest :: binary >>, iolist) when char > 0x7E do
    chars(rest, [iolist, char])
  end

  defp chars(after_quote(rest), iolist) do
    { leave_string(iolist), rest }
  end

  lc { escape, char } inlist Enum.zip('"\\bfnrt', '"\\\b\f\n\r\t') do
    defp chars(<< ?\\, unquote(escape), rest :: binary >>, iolist) do
      chars(rest, [iolist, unquote(char)])
    end
  end

  defp chars(<< ?\\, ?u, a1, b1, c1, d1,
                ?\\, ?u, a2, b2, c2, d2,
                rest :: binary >>, iolist) when a1 in [?d, ?D] and a2 in [?d, ?D] do
    first     = list_to_integer([a1, b1, c1, d1], 16)
    second    = list_to_integer([a2, b2, c2, d2], 16)
    codepoint = 0x10000 + ((first &&& 0x07ff) * 0x400) + (second &&& 0x03ff)

    chars(rest, [iolist, << codepoint :: utf8 >>])
  end

  defp chars(<< ?\\, ?u, a, b, c, d, rest :: binary >>, iolist) do
    codepoint = list_to_integer([a, b, c, d], 16)
    chars(rest, [iolist, << codepoint :: utf8 >>])
  end

  defp chars(<<>>, _), do: throw :partial
  defp chars(<< _ :: binary >>, _), do: throw :invalid

  defp digits(<< digit, rest :: binary >>) when is_digit(digit) do
    { digits, rest } = digits(rest)
    { [digit | digits], rest }
  end
  defp digits(rest), do: { [], rest }

  defp elements(<< bin :: binary >>, arr) do
    { val, rest } = value(bin)
    after_element(rest, [val | arr])
  end

  defp leave_array(arr),  do: :lists.reverse(arr)
  defp leave_object(obj), do: obj
  defp leave_string(str), do: iolist_to_binary(str)

  defp members(after_quote(rest), obj) do
    { key, rest } = chars(rest, [])
    pair(rest, obj, key)
  end

  defp members("}" <> rest, obj) do
    { leave_object(obj), rest }
  end

  defp members(<< ws, rest :: binary >>, obj) when is_whitespace(ws) do
    whitespace(rest) |> members(obj)
  end
  defp members(<<>>, _), do: throw :partial
  defp members(<< _ :: binary >>, _), do: throw :invalid

  defp number(<< rest :: binary >>, first) do
    case first do
      ?- ->
        { digits, rest } = digits(rest)
        int = [?- | digits]
      ?0 ->
        int = '+0'
      _  ->
        { digits, rest } = digits(rest)
        int = [?+, first | digits]
    end

    [frac, exp | rest] = number_frac(rest)
    { number(int, frac, exp), rest }
  end

  defp number(int, nil, nil), do: list_to_integer(int, 10)
  defp number(int, nil, exp) do
    int = list_to_integer(int, 10)
    exp = list_to_integer(exp, 10)

    pow(int, exp)
  end
  defp number(int, frac, nil), do: list_to_float(int ++ '.' ++ frac)
  defp number(int, frac, exp), do: list_to_float(int ++ '.' ++ frac ++ 'e' ++ exp)

  defp number_frac("." <> rest) do
    { digits, rest } = digits(rest)
    [digits | number_exp(rest)]
  end
  defp number_frac(rest), do: [nil | number_exp(rest)]

  defp number_exp(<< e, rest :: binary >>) when e in 'eE' do
    case rest do
      "-" <> rest -> sign = ?-
      "+" <> rest -> sign = ?+
      _           -> sign = ?+
    end

    { digits, rest } = digits(rest)
    [[sign | digits] | rest]
  end
  defp number_exp(rest), do: [nil | rest]

  defp pair(":" <> rest, obj, key) do
    { val, rest } = value(rest)

    obj = [{ key, val } | obj] #Dict.put_new(obj, key, val)
    after_pair(rest, obj)
  end

  defp pair(<< ws, rest :: binary>>, obj, key) when is_whitespace(ws) do
    whitespace(rest) |> pair(obj, key)
  end
  defp pair(<<>>, _, _), do: throw :partial
  defp pair(_, _, _),  do: throw :invalid

  defp pow(_, 0), do: 1
  defp pow(x, 1), do: x
  defp pow(x, y) when is_even(y), do: pow(x * x, div(y, 2))
  defp pow(x, y) when y > 1, do: x * pow(x, y - 1)
  defp pow(x, y) when y < 0, do: pow(1 / x, -y)

  defp value(after_quote(rest)), do: chars(rest, [])
  defp value("{"     <> rest), do: members(rest, [])
  defp value("["     <> rest), do: elements(rest, [])
  defp value("true"  <> rest), do: { true,  rest }
  defp value("false" <> rest), do: { false, rest }
  defp value("null"  <> rest), do: { nil,   rest }

  lc char inlist '-0123456789' do
    defp value(<< unquote(char), rest :: binary >>) do
      number(rest, unquote(char))
    end
  end

  defp value(<< ws, rest :: binary >>) when is_whitespace(ws) do
    whitespace(rest) |> value
  end
  defp value(<<>>), do: throw :partial
  defp value(<< _ :: binary >>), do: throw :invalid

  defp whitespace("    " <> rest), do: whitespace(rest)
  lc char inlist ' \t\n\r' do
    defp whitespace(<< unquote(char), rest :: binary >>), do: whitespace(rest)
  end
  defp whitespace(rest), do: rest
end
