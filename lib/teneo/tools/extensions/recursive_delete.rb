# frozen_string_literal: true

# Extension for Array
class Array

  # Removes all entries recursively for which the block returns true
  def recursive_delete(&block)
    each { |v| v.recursive_delete(&block) if Array === v || Hash === v }
    delete_if(&block)
  end
end

# Extension for Hash
class Hash
  # Removes all entries recursively for which the block returns true
  def recursive_delete(&block)
    each { |_, v| v.recursive_delete(&block) if Array === v || Hash === v }
    delete_if { |_, v| yield(v) }
  end
end
