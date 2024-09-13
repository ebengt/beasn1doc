defmodule GaDocsTest do
  use ExUnit.Case
  doctest GaDocs

  test "greets the world" do
    assert GaDocs.hello() == :world
  end

  test "find start" do
    [result | _] = content() |> GaDocs.find_start() |> GaDocs.find_start()

    assert result === "GPRSRecord	::= CHOICE"
  end

  test "structure content" do
    result = content() |> GaDocs.find_start() |> GaDocs.find_start() |> GaDocs.structure_one()

    {structure, rest} = result
    assert rest === ["", ""]

    assert structure === %{
             "GPRSRecord" => %{
               type: "CHOICE",
               content: [
                 ["sgsnPDPRecord", "[20]", "SGSNPDPRecord"],
                 ["tWAGRecord", "[97]", "TWAGRecord"]
               ]
             }
           }
  end

  test "structure content as strings" do
    structure = %{
      "GPRSRecord" => %{
        type: "CHOICE",
        content: [
          ["sgsnPDPRecord", "[20]", "SGSNPDPRecord"],
          ["tWAGRecord", "[97]", "TWAGRecord"]
        ]
      }
    }

    [result] = Enum.map(structure, &GaDocs.strings/1)

    assert result === [
             "# GPRSRecord",
             "| Parameter | Value | Type | Notes |",
             "|--|--|--|--|",
             "| sgsnPDPRecord | 20 | SGSNPDPRecord | |",
             "| tWAGRecord | 97 | TWAGRecord | |"
           ]
  end

  test "structure integer" do
    lines = ["AccessAvailabilityChangeReason		::= INTEGER (0..4294967295)"]

    result = GaDocs.structure_one(lines)

    {structure, rest} = result
    assert rest === []

    assert structure === %{
             "AccessAvailabilityChangeReason" => %{
               type: "INTEGER"
             }
           }
  end

  test "structure as strings" do
    structure = %{
      "AccessAvailabilityChangeReason" => %{
        type: "INTEGER"
      }
    }

    [result] = Enum.map(structure, &GaDocs.strings/1)

    assert result === [
             "# AccessAvailabilityChangeReason",
             "| Parameter | Type | Notes |",
             "|--|--|--|",
             "| AccessAvailabilityChangeReason | INTEGER | |"
           ]
  end

  #
  # Private functions
  #

  defp content(),
    do: """
    DEFINITIONS IMPLICIT TAGS	::=

    BEGIN
    LocationMethod
    FROM SS-DataTypes {itu-t identified-organization (4) etsi (0) mobileDomain (0) gsm-Access (2) modules (3) ss-DataTypes (2) version15 (15)}
    -- from TS 24.080 [209]

    ;

    --
    --  GPRS RECORDS
    --

    GPRSRecord	::= CHOICE

    --
    -- Record values 20, 22..27 are specific
    -- Record values 76, 77, 86 are MBMS specific
    -- Record values 78,79 and 92, 95, 96 are EPC specific
    --
    {
    sgsnPDPRecord			[20] SGSNPDPRecord,
    tWAGRecord				[97] TWAGRecord
    }

    """
end
