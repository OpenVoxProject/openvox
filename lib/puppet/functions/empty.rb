# frozen_string_literal: true

# Returns `true` if the given argument is an empty collection of values.
#
# This function can answer if one of the following is empty:
# * `Array`, `Hash` - having zero entries
# * `String`, `Binary` - having zero length
#
# For backwards compatibility, `Undef` is also accepted and returns `true`.
#
# @example Using `empty`
#
# ```puppet
# notice([].empty)
# notice(empty([]))
# # would both notice 'true'
# ```
#
# @since Puppet 5.5.0 - support for Binary
#
Puppet::Functions.create_function(:empty) do
  dispatch :collection_empty do
    param 'Collection', :coll
  end

  dispatch :sensitive_string_empty do
    param 'Sensitive[String]', :str
  end

  dispatch :string_empty do
    param 'String', :str
  end

  dispatch :binary_empty do
    param 'Binary', :bin
  end

  dispatch :undef_empty do
    param 'Undef', :x
  end

  def collection_empty(coll)
    coll.empty?
  end

  def sensitive_string_empty(str)
    str.unwrap.empty?
  end

  def string_empty(str)
    str.empty?
  end

  def binary_empty(bin)
    bin.length == 0
  end

  # For compatibility reasons - return true rather than error on undef
  # (Yes, it is strange, but undef was passed as empty string in 3.x API)
  #
  def undef_empty(x)
    true
  end
end
