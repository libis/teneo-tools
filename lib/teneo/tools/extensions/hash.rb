# frozen_string_literal: true

require_relative "blanco"

# Extension class for Hash
class Hash

  # Merges two hashes, but does so recursively.
  def recursive_merge(other_hash)
    self.merge(other_hash) do |_, old_val, new_val|
      if old_val.is_a? Hash
        old_val.recursive_merge new_val
      else
        new_val
      end
    end
  end unless method_defined? :recursive_merge

  # Merges two hashes in-place, but does so recursively.
  def recursive_merge!(other_hash)
    self.merge!(other_hash) do |_, old_val, new_val|
      if old_val.is_a? Hash
        old_val.recursive_merge new_val
      else
        new_val
      end
    end
  end unless method_defined? :recursive_merge!

  # Merges two hashes with priority for the first hash
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end unless method_defined? :reverse_merge

  # Merges two hashes in-place with priority for the first hash
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end unless method_defined? :reverse_merge!

  # Apply other hash values if current value is blanco
  def apply_defaults(other_hash, &block)
    self.merge(other_hash) { |_, v, w| (block_given? ? yield(v) : v.blanco?) ? w : v }
  end unless method_defined? :apply_defaults

  # Apply in-place other hash values if current value is blanco
  def apply_defaults!(other_hash, &block)
    self.merge!(other_hash) { |_, v, w| (block_given? ? yield(v) : v.blanco?) ? w : v }
  end unless method_defined? :apply_defaults!

  def symbolize_keys
    transform_keys { |k| k.to_sym rescue k }
  end unless method_defined? :symbolize_keys

  def symbolize_keys!
    replace(self.symbolize_keys)
  end unless method_defined? :symbolize_keys!

  def stringify_keys
    transform_keys(&:to_s)
  end unless method_defined? :stringify_keys

  def stringify_keys!
    replace(stringify_keys)
  end unless method_defined? :stringify_keys!

  def deep_symbolize_keys
    deep_transform_keys { |k| k.to_sym rescue k }
  end unless method_defined? :deep_symbolize_keys

  def deep_symbolize_keys!
    replace(deep_symbolize_keys)
  end unless method_defined? :deep_symbolize_keys!

  def deep_stringify_keys
    deep_transform_keys(&:to_s)
  end unless method_defined? :deep_stringify_keys

  def deep_stringify_keys!
    replace(deep_stringify_keys)
  end unless method_defined? :deep_stringify_keys!

  def deep_transform_keys(&block)
    obj_deep_transform_keys(self, &block)
  end unless method_defined? :deep_transform_keys

  def deep_transform_keys!(&block)
    replace(deep_transform_keys(&block))
  end unless method_defined? :deep_transform_keys!

  def deep_transform_values(&block)
    obj_deep_transform_values(self, &block)
  end unless method_defined? :deep_transform_values

  def deep_transform_values!(&block)
    replace(deep_transform_values(&block))
  end unless method_defined? :deep_transform_values!

  def obj_deep_transform_keys(obj, &block)
    case obj
    when Hash
      obj.each_with_object({}) { |(k, v), h| y[yield(k)] = obj_deep_transform_keys(v, &block) }
    when Array
      obj.map { |x| obj_deep_transform_keys(x, &block) }
    else
      obj
    end
  end unless method_defined? :obj_deep_transform_keys

  def obj_deep_transform_values(obj, &block)
    case obj
    when Hash
      obj.transform_values { |v| obj_deep_transform_values(v, &block) }
    when Array
      obj.map { |x| obj_deep_transform_values(x, &block) }
    else
      yield(obj)
    end
  end unless method_defined? :obj_deep_transform_values

  def transform_keys
    result = {}
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end unless method_defined? :transform_keys

  def transform_values
    return enum_for(:transform_values) { size } unless block_given?
    return {} if empty?
    result = self.class.new
    each do |key, value|
      result[key] = yield(value)
    end
    result
  end unless method_defined? :transform_values
end
