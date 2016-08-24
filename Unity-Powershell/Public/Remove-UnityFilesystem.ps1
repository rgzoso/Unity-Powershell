Function Remove-UnityFilesystem {

  <#
      .SYNOPSIS
      Delete a filesystem.
      .DESCRIPTION
      Delete a filesystem.
      You need to have an active session with the array.
      .NOTES
      Written by Erwan Quelin under MIT licence - https://github.com/equelin/Unity-Powershell/blob/master/LICENSE
      .LINK
      https://github.com/equelin/Unity-Powershell
      .PARAMETER Session
      Specify an UnitySession Object.
      .PARAMETER Name
      Filesystem name or Object.
      .PARAMETER Confirm
      If the value is $true, indicates that the cmdlet asks for confirmation before running. If the value is $false, the cmdlet runs without asking for user confirmation.
      .PARAMETER WhatIf
      Indicate that the cmdlet is run only to display the changes that would be made and actually no objects are modified.
      .EXAMPLE
      Remove-UnityFilesystem -Name 'FS01'

      Delete the filesystem named 'FS01'
      .EXAMPLE
      Get-UnityFilesystem -Name 'FS01' | Remove-UnityFilesystem

      Delete the filesystem named 'FS01'. The filesystem's informations are provided by the Get-UnityFilesystem through the pipeline.
  #>

  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param (
    [Parameter(Mandatory = $false,HelpMessage = 'EMC Unity Session')]
    $session = ($global:DefaultUnitySession | where-object {$_.IsConnected -eq $true}),
    [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'filesystem Name or filesystem Object')]
    $Name
  )

  Begin {
    Write-Verbose "Executing function: $($MyInvocation.MyCommand)"
  }

  Process {

    Foreach ($sess in $session) {

      Write-Verbose "Processing Session: $($sess.Server) with SessionId: $($sess.SessionId)"

      If ($Sess.TestConnection()) {

        Foreach ($n in $Name) {

          # Determine input and convert to UnityFilesystem object
          Switch ($n.GetType().Name)
          {
            "String" {
              $filesystem = get-UnityFilesystem -Session $Sess -Name $n
              $filesystemID = $filesystem.id
              $filesystemName = $n
            }
            "UnityFilesystem" {
              Write-Verbose "Input object type is $($n.GetType().Name)"
              $filesystemName = $n.Name
              If (Get-Unityfilesystem -Session $Sess -Name $n.Name) {
                        $filesystemID = $n.id
              }
            }
          }

          If ($filesystemID) {

            $UnityStorageRessource = Get-UnitystorageResource -Session $sess | ? {($_.Name -like $filesystemName) -and ($_.filesystem.id -like $filesystemID)}

            #Building the URI
            $URI = 'https://'+$sess.Server+'/api/instances/storageResource/' + $UnityStorageRessource.id
            Write-Verbose "URI: $URI"

            if ($pscmdlet.ShouldProcess($filesystemName,"Delete Filesystem")) {
              #Sending the request
              $request = Send-UnityRequest -uri $URI -Session $Sess -Method 'DELETE'
            }

            If ($request.StatusCode -eq '204') {

              Write-Verbose "Filesystem with ID: $filesystemID has been deleted"

            }
          } else {
            Write-Verbose "Filesystem $filesystemName does not exist on the array $($sess.Name)"
          }
        }
      } else {
        Write-Host "You are no longer connected to EMC Unity array: $($Sess.Server)"
      }
    }
  }

  End {}
}
