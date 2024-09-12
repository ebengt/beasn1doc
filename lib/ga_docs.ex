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

  def uncomment(file_content),
    do: file_content |> String.split("\n") |> Enum.filter(&uncomment_line?/1)

  def find_start(lines),
    do: lines |> Enum.drop_while(&uninteresting_line?/1)

  def strings({key, %{content: c}}) do
    heading = "# #{key}"
    names = "| Parameter | Value | Type | Notes |"
    divider = "|--|--|--|--|"
    [heading, names, divider | Enum.map(c, &strings_content/1)]
  end

  def structure_one([parameter_line | lines]),
    do: parameter_line |> parameter_type() |> structure_one(lines)

  #
  # Private functions
  #

  defp compund_not_started?("{" <> _), do: false
  defp compund_not_started?(_), do: true

  defp compund_not_ended?("}" <> _), do: false
  defp compund_not_ended?(_), do: true

  defp parameter_type(line) do
    [parameter, type | _] = String.split(line, "::=")
    {String.trim(parameter), String.trim(type)}
  end

  defp strings_content([parameter, value, parameter_is]),
    do: "| #{parameter} | #{strings_content_value(value)} | #{parameter_is} | |"

  defp strings_content([parameter, value, parameter_is, optional]),
    do: "| #{parameter} | #{strings_content_value(value)} | #{parameter_is} | #{optional} |"

  defp strings_content_value("[" <> value), do: String.trim_trailing(value, "]")

  defp structure_compund(lines) do
    [_start | rest] = lines |> Enum.drop_while(&compund_not_started?/1)
    {compund, [_end | rest]} = rest |> Enum.split_while(&compund_not_ended?/1)
    {Enum.map(compund, &structure_compund_split/1), rest}
  end

  defp structure_compund_split(line) do
    line |> String.trim_trailing(",") |> String.split()
  end

  defp structure_one({parameter, parameter_is}, lines) when parameter_is === "CHOICE" do
    {content, rest} = structure_compund(lines)
    {%{parameter => %{type: "CHOICE", content: content}}, rest}
  end

  defp uncomment_line?("--" <> _line), do: false
  defp uncomment_line?(_line), do: true

  defp uninteresting_line?(line), do: not String.contains?(line, "::=")
end
