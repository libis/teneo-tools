# frozen_string_literal: true

class NilClass
  def blanco?
    true
  end
end

class TrueClass
  def blanco?
    false
  end
end

class FalseClass
  def blanco?
    false
  end
end

class String
  BLANK_REGEX = /\A[[:space:]]*\z/.freeze
  def blanco?
    BLANK_REGEX.match?(self)
  end
end

class Array
  def blanco?
    (respond_to?(:empty?) ? !!empty? : false) || all? {|x| x.blanco?}
  end
end

class Hash
  def blanco?
    empty? || !any? {|_,v| !v.blanco?}
  end
end

class Object
  def blanco?
    respond_to?(:empty?) ? !!empty? : !self
  end
end
