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

  test "structure compound" do
    result = content() |> GaDocs.find_start() |> GaDocs.find_start() |> GaDocs.structure_one()

    {structure, rest} = result
    assert rest === ["", ""]

    assert structure === %{
             "GPRSRecord" => %{
               type: "CHOICE",
               compound: [
                 %{
                   parameter: "servingNodeiPv6Address",
                   value: "49",
                   type: "GSNAddress",
                   modifier: ["SEQUENCE", "OF"],
                   notes: "OPTIONAL"
                 },
                 %{parameter: "sgsnPDPRecord", value: "20", type: "SGSNPDPRecord"},
                 %{parameter: "tWAGRecord", value: "97", type: "TWAGRecord"}
               ]
             }
           }
  end

  test "structure compound as strings" do
    structure = %{
      type: "CHOICE",
      compound: [
        %{
          parameter: "servingNodeiPv6Address",
          value: "49",
          type: "GSNAddress",
          modifier: ["SEQUENCE", "OF"],
          notes: "OPTIONAL"
        },
        %{parameter: "sgsnPDPRecord", value: "20", type: "SGSNPDPRecord"},
        %{parameter: "tWAGRecord", value: "97", type: "TWAGRecord"}
      ]
    }

    result = GaDocs.strings("GPRSRecord", structure)

    assert result === [
             "# GPRSRecord",
             "| Parameter | Value | Type | Notes |",
             "|--|--|--|--|",
             "| servingNodeiPv6Address | 49 | SEQUENCE OF GSNAddress | OPTIONAL |",
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
               type: "INTEGER",
               notes: "(0..4294967295)"
             }
           }
  end

  test "structure PLMN" do
    lines = ["PLMN-Id		::= OCTET STRING (SIZE (3))"]

    result = GaDocs.structure_one(lines)

    {structure, rest} = result
    assert rest === []

    assert structure === %{
             "PLMN-Id" => %{
               modifier: ["OCTET", "STRING"],
               type: "(SIZE",
               notes: "(3))"
             }
           }
  end

  test "structure as strings" do
    structure = %{
      type: "INTEGER"
    }

    result = GaDocs.strings("AccessAvailabilityChangeReason", structure)

    assert result === [
             "# AccessAvailabilityChangeReason",
             "| Type | Notes |",
             "|--|--|",
             "| INTEGER | |"
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
    servingNodeiPv6Address				[49] SEQUENCE OF GSNAddress OPTIONAL,
    sgsnPDPRecord			[20] SGSNPDPRecord,
    tWAGRecord				[97] TWAGRecord
    }

    """
end
