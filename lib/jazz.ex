#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Jazz do
  defmacro __using__(_opts) do
    quote do
      alias Jazz, as: JSON
    end
  end

  @spec encode!(term, Keyword.t) :: String.t | no_return
  def encode!(data, options \\ []) do
    case encode(data, options) do
      { :ok, result } ->
        result

      { :error, error } ->
        raise ArgumentError, message: error
    end
  end

  defdelegate encode(data), to: Jazz.Encode, as: :it
  defdelegate encode(data, options), to: Jazz.Encode, as: :it

  defdelegate decode(string), to: Jazz.Decode, as: :it
  defdelegate decode(string, options), to: Jazz.Decode, as: :it

  defdelegate decode!(string), to: Jazz.Decode, as: :it!
  defdelegate decode!(string, options), to: Jazz.Decode, as: :it!

  defdelegate transform(data), to: Jazz.Decode
  defdelegate transform(data, options), to: Jazz.Decode
end
