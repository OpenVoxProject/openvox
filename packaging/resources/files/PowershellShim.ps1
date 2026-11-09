#!/usr/bin/env powershell
#requires -version 2.0

try {
  $here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
  . $here\PowershellShim-Helper.ps1

  $private:tempArgs = Get-ContentAsJson ($input -join "")

  Write-Debug "`nTask-shim deserialized arguments to Hashtable:`n"

  if ($tempArgs) {
    $tempArgs.GetEnumerator() | % {
      Write-Debug "* $($_.Key) ($($_.Value.GetType())):`n$($_.Value | ConvertTo-String)"
    }
  }

  $allowedArgs = (Get-Command $args[0]).Parameters.Keys
  $private:taskArgs = @{}
  $private:tempArgs.Keys | ? { $allowedArgs -contains $_ } | % { $private:taskArgs[$_] = $private:tempArgs[$_] }

  & $args[0] @taskArgs

} catch {
  Write-Error $_
  if ($LASTEXITCODE -eq $null) { $LASTEXITCODE = 1 }
}
exit $LASTEXITCODE
