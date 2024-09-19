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

  def main([file | parameters]) do
    file
    |> File.read!()
    |> find_start()
    |> Enum.filter(&uncomment_line?/1)
    |> structures(%{})
    |> filter(parameters)
    |> Enum.map(&strings/1)
    |> Enum.each(&IO.puts/1)
  end

  def find_start(binary) when is_binary(binary) do
    [_, rest] = String.split(binary, "BEGIN", parts: 2)
    String.split(rest, "\n")
  end

  def find_start(lines) when is_list(lines),
    do: lines |> Enum.drop_while(&uninteresting_line?/1)

  def strings({key, %{compound: c}}) do
    heading = "# #{key}"
    names = "| Parameter | Value | Type | Notes |"
    divider = "|--|--|--|--|"
    [heading, names, divider | Enum.map(c, &strings_content/1)]
  end

  def strings({key, %{type: t}}) do
    heading = "# #{key}"
    names = "| Parameter | Type | Notes |"
    divider = "|--|--|--|"
    result = "| #{key} | #{t} | |"
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

  defp filter(structures, parameters) do
    used = filter_parameters(structures, parameters, [])
    Map.take(structures, used)
  end

  defp filter_parameters(_structures, [], acc), do: acc

  defp filter_parameters(structures, parameters, acc) do
    content_parameters =
      Enum.flat_map(Map.take(structures, parameters), &filter_parameters_content/1)

    filter_parameters(structures, content_parameters, parameters ++ acc)
  end

  defp filter_parameters_content(%{content: [parameter | _]}), do: [parameter]
  defp filter_parameters_content(_), do: []

  defp parameter_type(line) do
    [parameter, rest] = String.split(line, "::=")
    type_curly_brace = String.split(rest) |> parameter_type_curly_brace()
    {String.trim(parameter), type_curly_brace}
  end

  defp parameter_type_curly_brace([type, "{" | _]), do: {type, "{"}
  defp parameter_type_curly_brace(other), do: {other, ""}

  defp strings_content(%{parameter: p, value: v, type: t, modifier: m, notes: n}),
    do: "| #{p} | #{v} | #{Enum.join(m, " ")} #{t} | #{n} |"

  defp strings_content(%{parameter: p, value: v, type: t, modifier: m}),
    do: "| #{p} | #{v} | #{Enum.join(m, " ")} #{t} | |"

  defp strings_content(%{parameter: p, value: v, type: t, notes: n}),
    do: "| #{p} | #{v} | #{t} | #{n} |"

  defp strings_content(%{parameter: p, value: v, type: t}),
    do: "| #{p} | #{v} | #{t} | |"

  defp strings_content([error]), do: error <> "\n"

  def structures([], acc), do: acc

  def structures(lines, acc) do
    {structure, rest} = lines |> find_start() |> structure_one()
    structures(rest, Map.merge(structure, acc))
  end

  defp structure_compound(lines) do
    [_start | rest] = lines |> Enum.drop_while(&compound_not_started?/1)
    {compund_lines, [_end | rest]} = rest |> Enum.split_while(&compound_not_ended?/1)

    f = fn line ->
      line |> String.trim_trailing(",") |> String.split() |> structure_compound_content()
    end

    {Enum.map(compund_lines, f), rest}
  end

  defp structure_compound_content([parameter, value | rest]) do
    content = rest |> Enum.reverse() |> structure_one_content()
    Map.merge(%{parameter: parameter, value: structure_compound_content_value(value)}, content)
  end

  defp structure_compound_content_value("[" <> value), do: String.trim_trailing(value, "]")

  defp structure_one({parameter_name, {[parameter_type], curly_brace}}, lines)
       when parameter_type === "CHOICE" or parameter_type === "SET" or
              parameter_type === "SEQUENCE" do
    {compound, rest} = structure_compound([curly_brace | lines])
    {%{parameter_name => %{type: parameter_type, compound: compound}}, rest}
  end

  #  defp structure_one({parameter, parameter_is}, lines) when parameter_is === "INTEGER" or parameter_is === "OCTET" or parameter_is === "IA5String" or parameter_is === "ENUMERATED" or parameter_is === "AccessPointNameNI" AccessPointNameOI
  defp structure_one({parameter_name, {parameter_type, ""}}, lines) do
    content = parameter_type |> Enum.reverse() |> structure_one_content()
    {%{parameter_name => content}, lines}
  end

  defp structure_one_content(["OPTIONAL", type_is]), do: %{type: type_is, notes: "OPTIONAL"}
  defp structure_one_content(["(" <> _ = note, type_is]), do: %{type: type_is, notes: note}

  defp structure_one_content(["OPTIONAL", type_is | modifier]),
    do: %{type: type_is, modifier: Enum.reverse(modifier), notes: "OPTIONAL"}

  defp structure_one_content(["(" <> _ = note, type_is | modifier]),
    do: %{type: type_is, modifier: Enum.reverse(modifier), notes: note}

  defp structure_one_content([type_is]), do: %{type: type_is}

  defp structure_one_content([type_is | modifier]),
    do: %{type: type_is, modifier: Enum.reverse(modifier)}

  defp uncomment_line?("--" <> _line), do: false
  defp uncomment_line?(""), do: false
  defp uncomment_line?(_line), do: true

  defp uninteresting_line?(line), do: not String.contains?(line, "::=")
end
