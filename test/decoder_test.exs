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
    assert JSON.decode!(%B/"lol"/)    == "lol"
    assert JSON.decode!(%B/"\\\r\n"/) == "\\\r\n"

    assert JSON.decode!(%B/"lol"/)          == "lol"
    assert JSON.decode!(%B/"\u00E6\u00DF"/)  == "æß"
    assert JSON.decode!(%B/"\uD834\uDD1E"/) == "𝄞"
  end

  test "decodes objects correctly" do
    assert JSON.decode!(%B/{"lol":"wut"}/, keys: :atoms)         == [lol: "wut"]
    assert JSON.decode!(%B/{"lol":{"omg":"wut"}}/, keys: :atoms) == [lol: [omg: "wut"]]
  end

  test "decodes arrays correctly" do
    assert JSON.decode!(%B/[1,2,3]/)                       == [1, 2, 3]
    assert JSON.decode!(%B/[{"lol":"wut"},{"omg":"wut"}]/, keys: :atoms) == [[lol: "wut"], [omg: "wut"]]
  end

  test "decodes records correctly" do
    assert JSON.decode!(%B/{"a":2,"b":3}/, as: Foo)  == Foo[a: 2, b: 3]
    assert JSON.decode!(%B/{"data":[2,3]}/, as: Bar) == Bar[a: 2, b: 3]
  end
end
