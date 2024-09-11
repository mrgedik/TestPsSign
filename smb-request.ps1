<#
.SYNOPSIS
Attempts an SMB connection to a specified IP address and share.
.DESCRIPTION
This Remote Action attempts to establish an SMB connection to a given IP address and share name
using the credentials of the user running the Nexthink Remote Action service.
.FUNCTIONALITY
On-demand
.INPUTS
ID  Label                           Description
1   TargetIP                        IP address of the target machine
2   ShareName                       Name of the share to connect to
.OUTPUTS
ID  Label                           Type            Description
1   ConnectionStatus                String          Status of the SMB connection attempt
2   ErrorMessage                    String          Error message if the connection failed
.NOTES
Context:            LocalSystem
Version:            1.0.1.0 - Updated to use service account credentials
Last Generated:     11 Sep 2024 - 17:30:00
#>

param(
    [Parameter(Mandatory=$true)][string]$TargetIP,
    [Parameter(Mandatory=$true)][string]$ShareName
)

$ERROR_EXCEPTION_TYPE = @{
    Network = '[Network error]'
    Input = '[Input error]'
    Internal = '[Internal error]'
}

Add-Type -Path "$env:NEXTHINK\RemoteActions\nxtremoteactions.dll"

function Test-InputParameters($TargetIP, $ShareName) {
    if (-not ($TargetIP -as [IPAddress])) {
        throw "$($ERROR_EXCEPTION_TYPE.Input) Invalid IP address format."
    }
    if ([string]::IsNullOrEmpty($ShareName)) {
        throw "$($ERROR_EXCEPTION_TYPE.Input) Share name cannot be empty."
    }
}

function Test-SMBConnection($TargetIP, $ShareName) {
    $uncPath = "\\$TargetIP\$ShareName"
    
    try {
        # Using Test-Path to check SMB connection
        if (Test-Path -Path $uncPath -ErrorAction Stop) {
            return $true, "Successfully connected to $uncPath"
        } else {
            return $false, "$($ERROR_EXCEPTION_TYPE.Network) Path not found: $uncPath"
        }
    }
    catch {
        return $false, "$($ERROR_EXCEPTION_TYPE.Network) Failed to connect to SMB share: $_"
    }
}

function Invoke-Main($TargetIP, $ShareName) {
    try {
        Test-InputParameters -TargetIP $TargetIP -ShareName $ShareName
        $connectionResult, $statusMessage = Test-SMBConnection -TargetIP $TargetIP -ShareName $ShareName
        
        [nxt]::WriteOutputString('ConnectionStatus', $(if ($connectionResult) { "Success" } else { "Failure" }))
        [nxt]::WriteOutputString('ErrorMessage', $(if (-not $connectionResult) { $statusMessage } else { "-" }))
    }
    catch {
        [nxt]::WriteOutputString('ConnectionStatus', "Failure")
        [nxt]::WriteOutputString('ErrorMessage', $_.Exception.Message)
        return 1
    }
    return 0
}

$exitCode = Invoke-Main -TargetIP $TargetIP -ShareName $ShareName
exit $exitCode
