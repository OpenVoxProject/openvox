test_name "resources declared in a class can be applied with include"

tag 'audit:high',
    'audit:unit',  # This should be covered at the unit layer.
    'shard:group1' # For splitting out groups of tests for slow test runners

manifest = %q{
class x {
  notify{'a':}
}
include x
}
apply_manifest_on(agents, manifest) do |result|
    fail_test "the resource did not apply" unless result.stdout.include?("defined 'message' as 'a'")
end
