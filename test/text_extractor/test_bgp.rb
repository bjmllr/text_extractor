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
end
