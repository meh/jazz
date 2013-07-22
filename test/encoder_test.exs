Code.require_file "test_helper.exs", __DIR__

defmodule EncoderTest do
  use ExUnit.Case, async: true

  defrecord Foo, [:a, :b]
  defrecord Bar, [:a, :b]

  defimpl JSON.Encoder, for: Bar do
    def to_json(Bar[a: a, b: b], _) do
      [data: [a, b]]
    end
  end

  test "encodes numbers correctly" do
    assert JSON.encode!(4)      == "4"
    assert JSON.encode!(2.3)    == "2.3"
    assert JSON.encode!(2.4583) == "2.4583"
  end

  test "encodes strings correctly" do
    assert JSON.encode!("lol")    == %B/"lol"/
    assert JSON.encode!("\\\r\n") == %B/"\\\r\n"/
  end

  test "encodes objects correctly" do
    assert JSON.encode!([lol: "wut"])        == %B/{"lol":"wut"}/
    assert JSON.encode!([lol: [omg: "wut"]]) == %B/{"lol":{"omg":"wut"}}/
  end

  test "encodes arrays correctly" do
    assert JSON.encode!([1, 2, 3])                    == %B/[1,2,3]/
    assert JSON.encode!([[lol: "wut"], [omg: "wut"]]) == %B/[{"lol":"wut"},{"omg":"wut"}]/
  end

  test "encodes records correctly" do
    assert JSON.encode!(Foo[a: 2, b: 3]) == %B/{"a":2,"b":3}/
    assert JSON.encode!(Bar[a: 2, b: 3]) == %B/{"data":[2,3]}/
  end
end
