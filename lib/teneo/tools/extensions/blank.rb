# frozen_string_literal: true

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end unless method_defined? :blank?
end

class String
  BLANK_RE = /\A[[:space:]]*\z/
  ENCODED_BLANKS = Hash.new do |h, enc|
    h[enc] = Regexp.new(BLANK_RE.source.encode(enc), BLANK_RE.options | Regexp::FIXEDENCODING)
  end

  def blank?
    empty? ||
      begin
        BLANK_RE.match?(self)
      rescue Encoding::CompatibilityError
        ENCODED_BLANKS[self.encoding].match?(self)
      end
  end
end
