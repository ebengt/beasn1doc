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

  def main([file]) do
    file
    |> File.read!()
    |> find_start()
    |> Enum.filter(&uncomment_line?/1)
    |> structures(%{})
    |> Enum.map(&strings/1)
    |> Enum.each(&IO.puts/1)
  end

  def find_start(binary) when is_binary(binary) do
    [_, rest] = String.split(binary, "BEGIN", parts: 2)
    String.split(rest, "\n")
  end

  def find_start(lines) when is_list(lines),
    do: lines |> Enum.drop_while(&uninteresting_line?/1)

  def strings({key, %{content: c}}) do
    heading = "# #{key}\n"
    names = "| Parameter | Value | Type | Notes |\n"
    divider = "|--|--|--|--|\n"
    [heading, names, divider | Enum.map(c, &strings_content/1)]
  end

  def strings({key, %{type: t}}) do
    heading = "# #{key}\n"
    names = "| Parameter | Type | Notes |\n"
    divider = "|--|--|--|\n"
    result = "| #{key} | #{t} | |\n"
    [heading, names, divider, result]
  end

  def structure_one([]),
    do: {%{}, []}

  def structure_one([parameter_line | lines]),
    do: parameter_line |> parameter_type() |> structure_one(lines)

  #
  # Private functions
  #

  defp compound_not_started?("{" <> _), do: false
  defp compound_not_started?(_), do: true

  defp compound_not_ended?("}" <> _), do: false
  defp compound_not_ended?(_), do: true

  defp parameter_type(line) do
    [parameter, rest] = String.split(line, "::=")
    type_curly_brace = String.split(rest) |> parameter_type_curly_brace()
    {String.trim(parameter), type_curly_brace}
  end

  defp parameter_type_curly_brace([type, "{" | _]), do: {type, "{"}
  defp parameter_type_curly_brace([type | _]), do: {type, ""}

  defp strings_content([parameter, value, parameter_is]),
    do: "| #{parameter} | #{strings_content_value(value)} | #{parameter_is} | |\n"

  defp strings_content([parameter, value, parameter_is, "OPTIONAL"]),
    do: "| #{parameter} | #{strings_content_value(value)} | #{parameter_is} | OPTIONAL |\n"

  defp strings_content([parameter, value | parameter_is_list]) do
    p = Enum.join(parameter_is_list, " ")
    "| #{parameter} | #{strings_content_value(value)} | #{p} | |\n"
  end

  defp strings_content([error]), do: error <> "\n"

  defp strings_content_value("[" <> value), do: String.trim_trailing(value, "]")
  defp strings_content_value(_value), do: "-"

  def structures([], acc), do: acc

  def structures(lines, acc) do
    {structure, rest} = lines |> find_start() |> structure_one()
    structures(rest, Map.merge(structure, acc))
  end

  defp structure_compound(lines) do
    [_start | rest] = lines |> Enum.drop_while(&compound_not_started?/1)
    {compund, [_end | rest]} = rest |> Enum.split_while(&compound_not_ended?/1)
    {Enum.map(compund, &structure_compound_split/1), rest}
  end

  defp structure_compound_split(line) do
    line |> String.trim_trailing(",") |> String.split()
  end

  defp structure_one({parameter, {parameter_is, curly_brace}}, lines)
       when parameter_is === "CHOICE" or parameter_is === "SET" or parameter_is === "SEQUENCE" do
    {content, rest} = structure_compound([curly_brace | lines])
    {%{parameter => %{type: parameter_is, content: content}}, rest}
  end

  #  defp structure_one({parameter, parameter_is}, lines) when parameter_is === "INTEGER" or parameter_is === "OCTET" or parameter_is === "IA5String" or parameter_is === "ENUMERATED" or parameter_is === "AccessPointNameNI" AccessPointNameOI
  defp structure_one({parameter, {parameter_is, ""}}, lines) do
    {%{parameter => %{type: parameter_is}}, lines}
  end

  defp uncomment_line?("--" <> _line), do: false
  defp uncomment_line?(""), do: false
  defp uncomment_line?(_line), do: true

  defp uninteresting_line?(line), do: not String.contains?(line, "::=")
end
