jazz - JSON handling library for Elixir
=======================================
Jazz is a JSON handling library written in Elixir, for Elixir.

Examples
--------

```elixir
JSON.encode!([name: "David", surname: "Davidson"])
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(%S/{"name":"David","surname":"Davidson"}/)
  |> IO.inspect # => [{ "name", "David" }, { "surname", "Davidson" }]

JSON.decode!(%S/{"name":"David","surname":"Davidson"}/, keys: :atoms)
  |> IO.inspect # => [name: "David", surname: "Davidson"]

# would raise if the keys weren't already existing atoms
JSON.decode!(%S/{"name":"David","surname":"Davidson"}/, keys: :atoms!)
  |> IO.inspect # => [name: "David", surname: "Davidson"]

defrecord Person, name: nil, surname: nil

JSON.encode!(Person[name: "David", surname: "Davidson"])
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(%S/{"name":"David","surname":"Davidson"}/, as: Person)
  |> IO.inspect # => Person[name: "David", surname: "Davidson"]

defimpl JSON.Encoder, for: HashDict do
  def to_json(self, options) do
    HashDict.to_list(self)
  end
end

defimpl JSON.Decoder, for: HashDict do
  def from_json({ _, parsed, _ }) do
    HashDict.new(parsed)
  end
end

JSON.encode!(HashDict.new([name: "David", surname: "Davidson"]))
  |> IO.puts # => {"name":"David","surname":"Davidson"}

JSON.decode!(%S/{"name":"David","surname":"Davidson"}/, as: HashDict)
  |> IO.inspect # => #HashDict<[{"name", "David" }, { "surname", "Davidson" }]>
```

Why yet another JSON library?
-----------------------------
Because I need it and I need it with these features, like it? Use it. Don't
like it? Don't use it.
