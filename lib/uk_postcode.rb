# -*- coding: utf-8 -*-
class UKPostcode
  MATCH = /\A
           \s*
           ( [A-PR-UWYZ01][A-Z01]? )    # area
           ( (?:[0-9IO!\"$%^&*\(\)]|£)(?:[0-9A-HJKMNPR-YIO!\"$%^&*\(\)]|£)? )  # district
           (?:
             \s*
             ( [0-9IO!\"$%^&*\(\)]|£ )  # sector
             ( [ABD-HJLNPQ-Z10]{2} )    # unit
                                     )?
           \s*
           \Z/x

  attr_reader :raw

  # Returns a new UKPostcode or BritishForcesPostcode as appropriate,
  # given a postcode as a string.
  #
  def self.parse(postcode_as_string)
    postcode_as_string =~ /^\s*BFP[O0]/i ? BritishForcesPostcode.new(postcode_as_string) : self.new(postcode_as_string)
  end

  # Initialise a new UKPostcode instance from the given postcode string
  #
  def initialize(postcode_as_string)
    @raw = postcode_as_string
  end

  # Returns true if the postcode is a valid full postcode (e.g. W1A 1AA) or outcode (e.g. W1A)
  #
  def valid?
    !!outcode
  end

  # Returns true if the postcode is a valid full postcode (e.g. W1A 1AA)
  #
  def full?
    !!(outcode && incode)
  end

  # The left-hand part of the postcode, e.g. W1A 1AA -> W1A
  #
  def outcode
    area && district && [area, district].join
  end

  # The right-hand part of the postcode, e.g. W1A 1AA -> 1AA
  #
  def incode
    sector && unit && [sector, unit].join
  end

  # The first part of the outcode, e.g. W1A 2AB -> W
  #
  def area
    letters(parts[0])
  end

  # The second part of the outcode, e.g. W1A 2AB -> 1A
  #
  def district
    digits(parts[1])
  end

  # The first part of the incode, e.g. W1A 2AB -> 2
  #
  def sector
    digits(parts[2])
  end

  # The second part of the incode, e.g. W1A 2AB -> AB
  #
  def unit
    letters(parts[3])
  end

  # Render the postcode as a normalised string, i.e. in upper case and with spacing.
  # Returns an empty string if the postcode is not valid.
  #
  def norm
    [outcode, incode].compact.join(" ")
  end
  alias_method :normalise, :norm
  alias_method :normalize, :norm

  alias_method :to_s,   :raw
  alias_method :to_str, :raw

  def inspect(*args)
    "<#{self.class.to_s} #{raw}>"
  end

protected

  def letters(s)
    s && s.tr("10", "IO")
  end

  def digits(s)
    # '£' needs to be dealt with separately because it doesn't work
    # with #tr and utf-8.
    s && s.tr('IO!"$%^&*()', "10124567890").gsub(/£/,'3')
  end

private

  def parts
    if @matched
      @parts
    else
      @matched = true
      matches = raw.upcase.match(MATCH) || []
      @parts = (1..4).map{ |i| matches[i] }
    end
  end
end

# A BFPO postcode.
#
# BFPO postcodes have a format like BFPO 43.
class BritishForcesPostcode < UKPostcode
  MATCH = /\A
           \s*
           (BFP[O0])\s*
           (c\/o)?\s*
           ([0-9]{1,4})\s*
           \Z/xi

  # Returns 'BFPO' or nil
  #
  def outcode
    return @outcode if defined? @outcode
    split_raw_postcode
    @outcode
  end

  # Returns the BFPO number
  #
  def incode
    return @incode if defined? @incode
    split_raw_postcode
    @incode
  end

private

  def split_raw_postcode
    matches = raw.match(MATCH) || []
    @outcode = matches[1] && "BFPO"
    @incode = [matches[2], matches[3]].compact.join(" ").downcase
    @incode = nil if @incode == ''
  end
end
