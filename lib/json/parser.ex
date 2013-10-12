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

  use Bitwise

  @compile :native
  @whitespace ' \t\n\r'
  @dquote << ?\" >>
  @escape << ?\\ >>

  def decode(bin) do
    value(bin)
  end

  defp after_pair("," <> rest, obj), do: members(rest, obj)
  defp after_pair("}" <> rest, obj), do: { leave_object(obj), rest }
  defp after_pair(<< ws, rest :: binary >>, obj) when ws in @whitespace do
    whitespace(rest) |> after_pair(obj)
  end

  defp after_element("," <> rest, arr), do: elements(rest, arr)
  defp after_element("]" <> rest, arr), do: { leave_array(arr), rest }
  defp after_element(<< ws, rest :: binary >>, arr) when ws in @whitespace do
    whitespace(rest) |> after_element(arr)
  end

  defp chars(<< bin :: binary >>, iolist) do
    n = chars_chunk_size(bin, 0)
    << chunk :: [binary, size(n)], rest :: binary >> = bin
    chars_escape(rest, [iolist, chunk])
  end

  defp chars_escape(@dquote <> rest, iolist) do
    { leave_string(iolist), rest }
  end

  lc { escape, char } inlist Enum.zip('"\\bfnrt', '"\\\b\f\n\r\t') do
    defp chars_escape(<< @escape, unquote(escape), rest :: binary >>, iolist) do
      chars(rest, [iolist, unquote(char)])
    end
  end

  defp chars_escape(<< @escape, ?u, a1, b1, c1, d1,
                       @escape, ?u, a2, b2, c2, d2,
                       rest :: binary >>, iolist) when a1 in [?d, ?D] and a2 in [?d, ?D] do
    first     = list_to_integer([a1, b1, c1, d1], 16)
    second    = list_to_integer([a2, b2, c2, d2], 16)
    codepoint = 0x10000 + ((first &&& 0x07ff) * 0x400) + (second &&& 0x03ff)
    chars(rest, [iolist, << codepoint :: utf8 >>])
  end

  defp chars_escape(<< @escape, ?u, a, b, c, d, rest :: binary >>, iolist) do
    chars(rest, [iolist, << list_to_integer([a, b, c, d], 16) :: utf8 >>])
  end

  defp chars_escape(<<>>, _), do: throw(:partial)
  defp chars_escape(<< _ :: binary >>, _), do: throw(:invalid)

  defp chars_chunk_size(@dquote <> _, n), do: n
  defp chars_chunk_size(@escape <> _, n), do: n
  defp chars_chunk_size(<< _ :: utf8, rest :: binary >>, n) do
    chars_chunk_size(rest, n + 1)
  end
  defp chars_chunk_size(<<>>, n), do: n

  defp digits(<< digit, rest :: binary >>) when digit in ?0..?9 do
    { digits, rest } = digits(rest)
    { [digit | digits], rest }
  end
  defp digits(rest), do: { [], rest }

  defp elements(<< bin :: binary >>, arr) do
    { val, rest } = value(bin)
    after_element(rest, [val | arr])
  end

  defp enter_array(<< bin :: binary >>) do
    elements(bin, [])
  end

  defp enter_object(<< bin :: binary >>) do
    members(bin, [])
  end

  defp enter_string(<< bin :: binary >>) do
    chars(bin, [])
  end

  defp leave_array(arr),  do: :lists.reverse(arr)
  defp leave_object(obj), do: :lists.reverse(obj)
  defp leave_string(str), do: iolist_to_binary(str)

  defp members(@dquote <> rest, obj) do
    { key, rest } = enter_string(rest)
    pair(rest, obj, key)
  end

  defp members("}" <> rest, obj) do
    { leave_object(obj), rest }
  end

  defp members(<< ws, rest :: binary >>, obj) when ws in @whitespace do
    whitespace(rest) |> members(obj)
  end
  defp members(<<>>, _), do: throw(:partial)
  defp members(<< _ :: binary >>, _), do: throw(:invalid)

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

  defp pair(<< ws, rest :: binary>>, obj, key) when ws in @whitespace do
    whitespace(rest) |> pair(obj, key)
  end
  defp pair(<<>>, _, _), do: throw(:partial)
  defp pair(<< _ :: binary >>, _, _),  do: throw(:invalid)

  defp pow(_, 0), do: 1
  defp pow(x, 1), do: x
  defp pow(x, y) when y &&& 1 === 0, do: pow(x * x, div(y, 2))
  defp pow(x, y) when y > 1, do: x * pow(x, y - 1)
  defp pow(x, y) when y < 0, do: pow(1 / x, -y)

  defp value(@dquote <> rest), do: enter_string(rest)
  defp value("{"     <> rest), do: enter_object(rest)
  defp value("["     <> rest), do: enter_array(rest)
  defp value("true"  <> rest), do: { true,  rest }
  defp value("false" <> rest), do: { false, rest }
  defp value("null"  <> rest), do: { nil,   rest }

  lc char inlist '-0123456789' do
    defp value(<< unquote(char), rest :: binary >>) do
      number(rest, unquote(char))
    end
  end

  defp value(<< ws, rest :: binary >>) when ws in @whitespace do
    whitespace(rest) |> value
  end
  defp value(<<>>), do: throw(:partial)
  defp value(<< _ :: binary >>), do: throw(:invalid)

  defp whitespace("    " <> rest), do: whitespace(rest)
  lc char inlist @whitespace do
    defp whitespace(<< unquote(char), rest :: binary >>), do: whitespace(rest)
  end
  defp whitespace(rest), do: rest
end
