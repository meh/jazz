Code.require_file "test_helper.exs", __DIR__

defmodule DecoderTest do
  use ExUnit.Case, async: true

  defrecord Foo, [:a, :b]
  defrecord Bar, [:a, :b]

  defimpl JSON.Encoder, for: Bar do
    def to_json(Bar[a: a, b: b], _) do
      [data: [a, b]]
    end
  end

  defimpl JSON.Decoder, for: Bar do
    def from_json({ _, parsed, _ }) do
      [a, b] = parsed["data"]

      Bar[a: a, b: b]
    end
  end

  test "decodes numbers correctly" do
    assert JSON.decode!("4")      == 4
    assert JSON.decode!("2.3")    == 2.3
    assert JSON.decode!("2.4583") == 2.4583
  end

  test "decodes strings correctly" do
    assert JSON.decode!(~S/"lol"/)    == "lol"
    assert JSON.decode!(~S/"\\\r\n"/) == "\\\r\n"

    assert JSON.decode!(~S/"lol"/)          == "lol"
    assert JSON.decode!(~S/"æß"/)           == "æß"
    assert JSON.decode!(~S/"\u00E6\u00DF"/) == "æß"
    assert JSON.decode!(~S/"\uD834\uDD1E"/) == "𝄞"
  end

  test "decodes objects correctly" do
    assert JSON.decode!(~S/{"lol":"wut"}/, keys: :atoms)         == [lol: "wut"]
    assert JSON.decode!(~S/{"lol":{"omg":"wut"}}/, keys: :atoms) == [lol: [omg: "wut"]]
  end

  test "decodes arrays correctly" do
    assert JSON.decode!(~S/[1,2,3]/)                       == [1, 2, 3]
    assert JSON.decode!(~S/[{"lol":"wut"},{"omg":"wut"}]/, keys: :atoms) == [[lol: "wut"], [omg: "wut"]]
  end

  test "decodes records correctly" do
    assert JSON.decode!(~S/{"a":2,"b":3}/, as: Foo)  == Foo[a: 2, b: 3]
    assert JSON.decode!(~S/{"data":[2,3]}/, as: Bar) == Bar[a: 2, b: 3]
  end

  test "decodes nested as" do
    decoded = JSON.decode!(~S/{"foo": {"a": 2, "b": 3}, "bar": {"data": [2, 3]}, "baz": 23}/,
      as: [foo: Foo, bar: Bar])

    assert decoded["foo"] == Foo[a: 2, b: 3]
    assert decoded["bar"] == Bar[a: 2, b: 3]
    assert decoded["baz"] == 23
  end

  test "decodes nested as with keys" do
    decoded = JSON.decode!(~S/{"foo": {"a": 2, "b": 3}, "bar": {"data": [2, 3]}, "baz": 23}/,
      as: [foo: Foo, bar: Bar], keys: :atoms)

    assert decoded[:foo] == Foo[a: 2, b: 3]
    assert decoded[:bar] == Bar[a: 2, b: 3]
    assert decoded[:baz] == 23
  end
end
