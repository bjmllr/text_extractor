require_relative "../test_helper"
require "text_extractor"

# examples based on the output of various "show bgp" commands on certain
# router appliances
class TestTextExtractorBgp < Minitest::Test
  INPUT = unindent(<<-END)
    BGP neighbor is foo, vrf bar
     Remote AS 1243
     Description: foobar
     For Address Family: spam eggs
     BGP state = confusion
     Policy for incoming advertisements is myinpolicy
     Policy for outgoing advertisements is myoutpolicy extra
     31337 accepted prefixes, 42 are bestpaths
     Prefix advertised 23, suppressed

    BGP neighbor is kilroy, vrf washere
     This neighbor is down. Nothing to see here, move along.

    BGP neighbor is bar, vrf foo
     Remote AS 1243
     Description: barfoo
     For Address Family: beer 99
     BGP state = disarray
     Policy for incoming advertisements is otherin 22
     Policy for outgoing advertisements is otherout
     1337 accepted prefixes, 40 are bestpaths
     Prefix advertised 0, suppressed
    END

  OUTPUT = [
    {
      bgp_neighbor: "foo",
      vrf_name: "bar",
      asn_remote: "1243",
      description: "foobar",
      address_family: "spam eggs",
      bgp_state: "confusion",
      policy_in: "myinpolicy",
      policy_out: "myoutpolicy extra",
      prefixes_received: "31337",
      prefixes_advertised: "23"
    },

    {
      bgp_neighbor: "kilroy",
      vrf_name: "washere"
    },

    {
      bgp_neighbor: "bar",
      vrf_name: "foo",
      asn_remote: "1243",
      description: "barfoo",
      address_family: "beer 99",
      bgp_state: "disarray",
      policy_in: "otherin 22",
      policy_out: "otherout",
      prefixes_received: "1337",
      prefixes_advertised: "0"
    }
  ]

  EXTRACTOR = TextExtractor.new do
    value :bgp_neighbor, /\S+/
    value :vrf_name, /\S+/
    value :asn_remote, /\d+/
    value :description, /\S+/
    value :bgp_state, /\S+/
    value :address_family, /\w+\s+\w+/
    value :policy_in, /\S+\s*\S*/
    value :policy_out, /\S+\s*\S*/
    value :prefixes_received, /\d+/
    value :prefixes_advertised, /\d+/

    record do
      /
      BGP neighbor is #{bgp_neighbor}, vrf #{vrf_name}
       Remote AS #{asn_remote}
       Description: #{description}
       For Address Family: #{address_family}
       BGP state = #{bgp_state}
       Policy for incoming advertisements is #{policy_in}
       Policy for outgoing advertisements is #{policy_out}
       #{prefixes_received}\s+accepted prefixes,\s+\d+ are bestpaths
       Prefix advertised\s+#{prefixes_advertised}, suppressed
      /
    end

    record do
      /
      BGP neighbor is #{bgp_neighbor}, vrf #{vrf_name}
       This neighbor is down. Nothing to see here, move along.
      /
    end
  end

  def test_multiple_record_definitions_with_multiple_instances
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
  end

  SUMMARY_INPUT = unindent(<<-END)
    Neighbor          AS  Up/Down  St/PfxRcd
    111.11.1.11    65001 00:00:00 Idle
    222.22.2.22    65002 00:00:10 12345
    END

  SUMMARY_EXTRACTOR = TextExtractor.new do
    value :neighbor, /\S+/
    integer :as
    value :time, /\S+/
    value(:prefixes, /\d+/) { |value| (value || 0).to_i }
    value(:state, /\w+/) { |value| value || "Established" }

    record { /#{neighbor}\s+#{as}\s+#{time}\s+(?:#{prefixes}|#{state})/ }
  end

  SUMMARY_OUTPUT = [
    {
      neighbor: "111.11.1.11",
      as: 65001, time: "00:00:00", prefixes: 0, state: "Idle"
    }, {
      neighbor: "222.22.2.22",
      as: 65002, time: "00:00:10", prefixes: 12345, state: "Established"
    }
  ]

  def test_record_with_mutually_exclusive_values
    assert_equal SUMMARY_OUTPUT, SUMMARY_EXTRACTOR.scan(SUMMARY_INPUT)
  end
end
