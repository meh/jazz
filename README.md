jazz - JSON handling library for Elixir
=======================================
Jazz is a JSON handling library written in Elixir, for Elixir.

Examples
--------

```elixir
use Jazz

JSON.encode!(%{name: "David", surname: "Davidson"})
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(~S/{"name":"David","surname":"Davidson"}/)
  |> IO.inspect # => %{"name" => "David", "surname" => "Davidson"}

JSON.decode!(~S/{"name":"David","surname":"Davidson"}/, keys: :atoms)
  |> IO.inspect # => %{name: "David", surname: "Davidson"}

# would raise if the keys weren't already existing atoms
JSON.decode!(~S/{"name":"David","surname":"Davidson"}/, keys: :atoms!)
  |> IO.inspect # => %{name: "David", surname: "Davidson"}

defmodule Person do
  defstruct name: nil, surname: nil
end

JSON.encode!(%Person{name: "David", surname: "Davidson"})
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(~S/{"name":"David","surname":"Davidson"}/, as: Person)
  |> IO.inspect # => %Person{name: "David", surname: "Davidson"}

defimpl JSON.Encoder, for: HashDict do
  def to_json(self, options) do
    HashDict.to_list(self) |> Enum.into(%{})
  end
end

defimpl JSON.Decoder, for: HashDict do
  def from_json(_new, parsed, _options) do
    parsed |> Enum.into(HashDict.new)
  end
end

JSON.encode!(HashDict.new([name: "David", surname: "Davidson"]))
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(~S/{"name":"David","surname":"Davidson"}/, as: HashDict)
  |> IO.inspect # => #HashDict<[{"name", "David" }, { "surname", "Davidson" }]>
```
