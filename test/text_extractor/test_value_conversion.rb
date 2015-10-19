require "ipaddr"
require_relative "../test_helper"
require "text_extractor"

class TestTextExtractorValueConverstion < Minitest::Test
  INPUT = unindent(<<-END)
    String: 1111
     Integer: 12
     Float Whole: 13
     Float Fraction: .14
     Rational: 1/5
     IPv4 Address: 1.1.1.16
     IPv6 Address: 2001::17
     IP Network: 1.1.1.18/30
     Boolean: True
     Custom: Reverse this!
    END

  EXTRACTOR = TextExtractor.new do
    value :some_string, /\w+/
    integer :some_integer
    float :some_float
    float :some_fraction
    rational :some_rational
    ipaddr :some_ipv4
    ipaddr :some_ipv6
    ipnetaddr :some_ipnet
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
       IP Network: #{some_ipnet}
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
      some_ipnet: IPAddr.new("1.1.1.18/30"),
      some_boolean: true,
      reversed: "!siht esreveR"
    }
  ]

  def test_value_conversions
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
  end
end
