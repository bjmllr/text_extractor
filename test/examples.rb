require 'ipaddr'

# test data
module Example
  class << self
    def unindent(s)
      s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, "")
    end
  end

  # examples based on the output of various "show bgp" commands on certain
  # router appliances
  module BGP
    # show bgp neighbor
    module Neighbor
      INPUT1 = Example.unindent(<<-END)
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
      # end INPUT1

      OUTPUT1 = [
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
      ] # OUTPUT1 = [

      EXTRACTOR1 = TextExtractor.new do
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
      end # EXTRACTOR1 = TextExtractor.new do
    end # module Neighbor
  end # module BGP

  module ValueConversion
    INPUT = Example.unindent(<<-END)
        String: 1111
         Integer: 12
         Float Whole: 13
         Float Fraction: .14
         Rational: 1/5
         IPv4 Address: 1.1.1.16
         IPv6 Address: 2001::17
         Boolean: True
         Custom: Reverse this!
      END
    # end INPUT

    EXTRACTOR = TextExtractor.new do
      value :some_string, /\w+/
      integer :some_integer
      float :some_float
      float :some_fraction
      rational :some_rational
      ipaddr :some_ipv4
      ipaddr :some_ipv6
      boolean :some_boolean
      value(:reversed, /[^\n]+/) { |val| val.reverse }

      record do
        /
        String: #{some_string}
         Integer: #{some_integer}
         Float Whole: #{some_float}
         Float Fraction: #{some_fraction}
         Rational: #{some_rational}
         IPv4 Address: #{some_ipv4}
         IPv6 Address: #{some_ipv6}
         Boolean: #{some_boolean}
         Custom: #{reversed}
        /
      end
    end # EXTRACTOR = TextExtractor.new do

    OUTPUT = [
      {
        some_string: "1111",
        some_integer: 12,
        some_float: 13.0,
        some_fraction: 0.14,
        some_rational: Rational(1, 5),
        some_ipv4: IPAddr.new("1.1.1.16"),
        some_ipv6: IPAddr.new("2001:0:0:0:0:0:0:17"),
        some_boolean: true,
        reversed: "!siht esreveR"
      }
    ] # OUTPUT = [
  end # module ValueConversion

  module Factories
    INPUT = Example.unindent(<<-END)
        whowhere Rene Descartes France
        where America
        whowhere Bertrand Russell Wales
        where China
      END
    # end INPUT

    WhoWhere = Struct.new(:person, :place)
    Where = Struct.new(:place)

    EXTRACTOR = TextExtractor.new do
      value :person, /\w+ \w+/
      value :place, /\w+/

      record(WhoWhere) do
        /
        whowhere #{person} #{place}
        /
      end

      record(Where) do
        /
        where #{place}
        /
      end
    end # EXTRACTOR = TextExtractor.new do

    OUTPUT = [
      WhoWhere.new("Rene Descartes", "France"),
      Where.new("America"),
      WhoWhere.new("Bertrand Russell", "Wales"),
      Where.new("China")
    ] # OUTPUT = [
  end # module Factories

  module Filldown
    INPUT = Example.unindent(<<-END)
        Philosophers:
        Rene Descartes
        Bertrand Russell

        Chemists:
        Alfred Nobel
        Marie Curie
      END
    # end INPUT

    EXTRACTOR = TextExtractor.new do
      value :occupation, /\w+/
      value :name, /\w+ \w+/

      filldown do
        /
        #{occupation}:
        /x
      end

      record(fill: :occupation) do
        /
        #{name}
        /x
      end
    end

    OUTPUT = [
      { occupation: "Philosophers", name: "Rene Descartes" },
      { occupation: "Philosophers", name: "Bertrand Russell" },
      { occupation: "Chemists", name: "Alfred Nobel" },
      { occupation: "Chemists", name: "Marie Curie" }
    ] # OUTPUT = [
  end # module Filldown
end # module Example
