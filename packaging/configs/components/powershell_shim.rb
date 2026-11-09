# This lays down the PowerShell shim that runs tasks with the powershell
# input method. Choria's task support looks for it in the same directory
# as execution_wrapper.
component "powershell_shim" do |pkg, settings, platform|
  pkg.add_source "file://resources/files/PowershellShim.ps1"
  pkg.add_source "file://resources/files/PowershellShim-Helper.ps1"
  pkg.install_file "PowershellShim.ps1", "#{settings[:bindir]}/PowershellShim.ps1", mode: '0755'
  pkg.install_file "PowershellShim-Helper.ps1", "#{settings[:bindir]}/PowershellShim-Helper.ps1", mode: '0755'
end
