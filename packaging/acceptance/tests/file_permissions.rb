# SDDL Decoder Ring
#
# O:SY => owner system
# G:SY => group system
# D:   => DACL
#   Flags
#     P  => protected
#     AI => automatic inheritance has been computed
# ACES (ace1)(ace2)...
#   Type
#     A => allow
#   Inheritance Flags
#     OI => object inherit (affects child files)
#     CI => container inherit (affects child directories)
#     ID => inherited from a parent
#   Access Right
#     FA       => file all 0x1f01ff
#     0x1200a9 => file read (0x00120089) | file execute (0x001200A0)
#   Trustee SID
#     SY => system
#     BA => builtin local admins
#     WD => world (everyone)
#
script = <<-'SCRIPT'
$SDDL_DIR_ADMIN_ONLY = "O:SYG:SYD:P(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)"
$SDDL_FILE_ADMIN_ONLY = "O:SYG:SYD:AI(A;ID;FA;;;SY)(A;ID;FA;;;BA)"
$SDDL_DIR_INHERITED_ADMIN_ONLY = "O:SYG:SYD:AI(A;OICIID;FA;;;SY)(A;OICIID;FA;;;BA)"
$SDDL_DIR_EVERYONE = "O:SYG:SYD:P(A;OICI;0x1200a9;;;WD)(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)"

function Compare-Sddl {
    param (
        [String]$Path,
        [String]$Expected
    )

    $acl = Get-Acl $Path

    if ($acl.Sddl -eq $Expected) {
        Write-Host "Path $($Path) matched $($Expected)"
    } else {
        Write-Host "Security Descriptor does not match!"
        Write-Host "Actual:"
        Write-Host "Path: $($Path)"
        Write-Host "Sddl: $($acl.Sddl)"
        Write-Host "Protected: $($acl.AreAccessRulesProtected)"
        Write-Host "Owner: $($acl.Owner)"
        Write-Host "Group: $($acl.Group)"
        Write-Host "DACL:"
        Write-Host $acl.AccessToString
        Write-Host
        Write-Host "Expected:"
        Write-Host $Expected
        exit(1)
    }
}

# Make sure public directories allow everyone read & execute
Compare-Sddl -Path C:\ProgramData\PuppetLabs\ -Expected $SDDL_DIR_EVERYONE
Compare-Sddl -Path C:\ProgramData\PuppetLabs\facter -Expected $SDDL_DIR_EVERYONE

# Make sure sensitive directories restrict permissions
Compare-Sddl -Path C:\ProgramData\PuppetLabs\code -Expected $SDDL_DIR_ADMIN_ONLY
Compare-Sddl -Path C:\ProgramData\PuppetLabs\puppet -Expected $SDDL_DIR_ADMIN_ONLY
Compare-Sddl -Path C:\ProgramData\PuppetLabs\pxp-agent -Expected $SDDL_DIR_ADMIN_ONLY

# Make sure directory and file created by packaging inherit from parent
Compare-Sddl -Path C:\ProgramData\PuppetLabs\code\environments\production -Expected $SDDL_DIR_INHERITED_ADMIN_ONLY
Compare-Sddl -Path C:\ProgramData\PuppetLabs\code\environments\production\environment.conf -Expected $SDDL_FILE_ADMIN_ONLY

# Ensure we didn't miss anything, Exclude doesn't work right on 2008r2
$expected=@("facter","code","puppet","pxp-agent");
$children = Get-ChildItem -Path C:\ProgramData\PuppetLabs
if ($children.Length -ne $expected.Length) {
   $unexpected = Compare-Object -ReferenceObject $children -DifferenceObject $expected
   $files = $unexpected -Join ","
   Write-Host "Unexpected files: $($files)"
   exit(1)
}
SCRIPT

test_name 'PA-2019: Verify file permissions' do
  skip_test 'requires version file which is created by AIO' if [:gem, :git].include?(@options[:type])

  agents.each do |agent|
    next if agent.platform !~ /windows/

    execute_powershell_script_on(agent, script)
  end
end
