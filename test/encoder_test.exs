Code.require_file "test_helper.exs", __DIR__

defmodule EncoderTest do
  use ExUnit.Case, async: true
  use Jazz

  defmodule Foo do
    defstruct [:a, :b]
  end

  defmodule Bar do
    defstruct [:a, :b]

    defimpl JSON.Encoder do
      def to_json(%Bar{a: a, b: b}, _) do
        %{data: [a, b]}
      end
    end
  end

  defmodule Baz do
    defstruct [:a, :b]

    defimpl JSON.Encoder do
      def to_json(new, _) do
        new
      end
    end
  end

  test "encodes numbers correctly" do
    assert JSON.encode!(4)      == "4"
    assert JSON.encode!(2.3)    == "2.3"
    assert JSON.encode!(2.4583) == "2.4583"
  end

  test "encodes strings correctly" do
    assert JSON.encode!("lol")    == ~S/"lol"/
    assert JSON.encode!("\\\r\n") == ~S/"\\\r\n"/
    assert JSON.encode!("æß") == ~S/"æß"/

    assert JSON.encode!("lol", escape: :unicode) == ~S/"lol"/
    assert JSON.encode!("æß", escape: :unicode)  == ~S/"\u00E6\u00DF"/
    assert JSON.encode!("𝄞", escape: :unicode)   == ~S/"\uD834\uDD1E"/
  end

  test "encodes objects correctly" do
    assert JSON.encode!(%{lol: "wut"})        == ~S/{"lol":"wut"}/
    assert JSON.encode!(%{lol: %{omg: "wut"}}) == ~S/{"lol":{"omg":"wut"}}/
  end

  test "encodes arrays correctly" do
    assert JSON.encode!([1, 2, 3])                      == ~S/[1,2,3]/
    assert JSON.encode!([%{lol: "wut"}, %{omg: "wut"}]) == ~S/[{"lol":"wut"},{"omg":"wut"}]/
  end

  test "encodes records correctly" do
    assert JSON.encode!(%Foo{a: 2, b: 3}) == ~S/{"a":2,"b":3}/
    assert JSON.encode!(%Bar{a: 2, b: 3}) == ~S/{"data":[2,3]}/
  end

  test "errors on recursive encoding" do
    assert JSON.encode(%Baz{}) == { :error, :recursive }
  end
end
