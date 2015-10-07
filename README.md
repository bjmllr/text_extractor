## TextExtractor: Easily Extract Data From Text

TextExtractor is a simple DSL for extracting data from text which follows a simple, consistent format, but which is not a well known format such as XML, JSON, or YAML, and for which conventional regular expression syntax might be too bulky or hard to follow.  It is inspired by the TextFSM project (https://code.google.com/p/textfsm/).

## Installation

Add this to your Gemfile:

```
gem "text_extractor", git: "https://github.com/bjmllr/text_extractor.git"
```

TextExtractor requires Ruby 2.  There are no other dependencies.

## Example And Explanation

TextExtractor instances are wrappers around regular expressions.  They are defined using a simple DSL that breaks the regexp into `value`s and `record`s, and they emit arrays of hashes when applied to text.

Here is a simple example to extract some information from a BGP router which is provided in a format that looks like this:

```
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
```

The extractor is defined in a block passed to `TextExtractor.new`:

```
bgp_neighbors = TextExtractor.new do
  # values go here
  # records go here
end
```

The first part of the definition is declaring the possible `value`s. Each `value` consists of a name and a tiny regular expression:

```
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
```

Within an extractor definition, each `value` must have a unique name, since they will eventually be placed into a hash together.

The regexp associated with each `value` is interpolated into one or more `record` regexps, so it's important that they are not anchored here.

The other part of the definition is defining one or more `record`s.  A `record` is just a regular expression, but it uses a special syntax:

```
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
```

Adding a second `record` means that there are two possible formats, equivalent to alternation (`|`) in a standard regexp (and this is how it is implemented).  Of course, it is possible to have any number of `record`s.

The `record` regexp syntax has a few differences to standard regexps which are intended to improve readability.

First, the interpolated sections (`#{value_name}`) will match the same-named values defined previously, and the matched values will be placed into a hash, one per instance of the record in the input.  This is implemented using named capture groups, but is more concise and modular.

Second, whitespace at the beginning or end of the regexp is removed, but not internally, which keeps the regexp visually similar to the text it is meant to match, in contrast with an extended regexp.  Also in contrast with an extended regexp, it is not possible to place comments inside a `record` regexp, but the interpolated `value`s serve a similar purpose in most cases.

Third, record regexps are unindented according to the indentation of the last line, so it's possible to nicely represent an unindented section of text in indented code, or an indented section of text, by indenting the internal regexp lines relative to the closing `/`.

Now we can run the extractor on some text with `TextExtractor#scan`:

```
bgp_neighbors.scan(text)
```

Successful output will be an array of hashes.  For our example, we can expect the following data:

```
[
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
```

### Extracting Non-String Values

A block passed to `value` will specify how the extracted string should be interpreted. In the above example, were we to use the following value definitions:

```ruby
value(:asn_remote) { |str| str.to_i }
value(:prefixes_received) { |str| str.to_i }
value(:prefixes_advertised) { |str| str.to_i }
```

These values would be converted from strings to integers before being
returned. The first record of the output might include the following:

```
  {
    ...
    asn_remote: 1243,
    ...
    prefixes_received: 31337,
    prefixes_advertised: 23
  },
```

The following methods are available for extracting values from the Ruby
core and standard library:

* `integer`
* `float`
* `rational`
* `ipaddr`

Since such types have unambiguous string representations, a minimal
Regexp is provided for each one. These defaults are highly permissive,
so it may be desirable to provide stricter ones depending on your
application.

### Factories

By default, records are converted into hashes, but it's possible to
specify a Struct or other factory object to use in place of a hash.

```ruby
extractor = TextExtractor.new do
  WhoWhere = Struct.new(:person, :place)
  Where = Struct.new(:place)

  value :person, /\w+ \w+/
  value :place, /\w+/

  record(factory: WhoWhere) do
    /
    whowhere #{person} #{place}
    /
  end

  record(factory: Where) do
    /
    where #{place}
    /
  end
end
```

Given this input:

```
whowhere Rene Descartes France
where America
whowhere Bertrand Russell Wales
where China
```

We should expect `extractor.scan` to return:

```ruby
[
  WhoWhere.new("Rene Descartes", "France"),
  Where.new("America"),
  WhoWhere.new("Bertrand Russell", "Wales"),
  Where.new("China")
]
```

### Filldown

Some texts may contain groups of records among which some common
attribute is only specified once. For example, consider this list of
people, grouped by occupation:

```
Philosophers:
Rene Descartes
Bertrand Russell

Chemists:
Alfred Nobel
Marie Curie
```

From this, we may want to extract the following data:

```ruby
[
  { occupation: "Philosophers", name: "Rene Descartes" },
  { occupation: "Philosophers", name: "Bertrand Russell" },
  { occupation: "Chemists", name: "Alfred Nobel" },
  { occupation: "Chemists", name: "Marie Curie" }
]
```

A new concept is required to achieve this using a TextExtractor:
`filldown`. A `filldown` is a special `record` that does not generate
rows of data, rather it modifies any row that follows it. Here is the
`TextExtractor`, using `filldown`, that will perform the desired
extraction:

```ruby
TextExtractor.new do
  value :occupation, /\w+/
  value :name, /\w+ \w+/

  filldown do
    /
    #{occupation}:$
    /
  end

  record(fill: :occupation) do
    /
    #{name}
    /
  end
end

```

## Tests

TextExtractor uses MiniTest.  You can run the tests from the project root like so:

```
ruby test/test_*.rb
```

## Contributors

Pull requests with tests are welcome.

## License

http://mit-license.org/
