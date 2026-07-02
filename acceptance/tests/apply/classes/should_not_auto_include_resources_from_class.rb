test_name "resources declared in classes are not applied without include"

tag 'audit:high',
    'audit:unit',  # This should be covered at the unit layer.
    'shard:group2' # For splitting out groups of tests for slow test runners

manifest = %q{ class x { notify { 'test': message => 'never invoked' } } }
apply_manifest_on(agents, manifest) do |result|
    fail_test "found the notify despite not including it" if
        result.stdout.include? "never invoked"
end
