defmodule GaDocs do
  @moduledoc """
  Documentation for `GaDocs`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GaDocs.hello()
      :world

  """
  def hello do
    :world
  end

  def main([file | types]) do
    extension = Path.extname(file)

    file
    |> File.read!()
    |> docs(types, extension)
    |> Enum.each(&IO.puts/1)
  end

  #
  # Private functions
  #

  defp docs(content, types, ".asn1"), do: GaDocs.ASN1.format(content, types)
  defp docs(content, _types, ".consumer"), do: GaDocs.Gnat.format(content, "consumer")
  defp docs(content, _types, ".stream"), do: GaDocs.Gnat.format(content, "stream")
end
