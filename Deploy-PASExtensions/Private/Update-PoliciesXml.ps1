function Update-PoliciesXml {
    param (
        [string]$PVWASettingsFile,
        [string]$PlatformId
    )

    $TemporaryFile = New-TemporaryFile

    Open-PVSafe -safe PVWAConfig
    Get-PVFile -safe PVWAConfig -folder root -file Policies.xml -localFolder $TemporaryFile.DirectoryName -localFile $TemporaryFile.Name

    $PoliciesXml = [xml](Get-Content $TemporaryFile)
    $PVWASettingsXml = [xml](Get-Content $PVWASettingsFile)

    # Search via PlatformId as it could be a Policy, Usage, whatever.
    $ExistingPolicyElement = $PoliciesXml.SelectSingleNode("//Policy[@ID='$PlatformId'] | //Usage[@ID='$PlatformId']")
    if ($null -ne $ExistingPolicyElement) {
        # Import the Policy element from the PVWASettingsFile to the PoliciesXml document.
        $NewPolicyElement = $PoliciesXml.ImportNode($PVWASettingsXml.SelectSingleNode("//*[@ID='$PlatformId']"), $true)

        # Add the new policy element we imported, replace the old one.
        $ExistingPolicyElement.ParentNode.ReplaceChild($NewPolicyElement, $ExistingPolicyElement)

        # Full path always needs to be provided with .Save().
        $PoliciesXml.Save($TemporaryFile.FullName)

        Add-PVFile -safe PVWAConfig -folder root -file 'Policies.xml' -localFolder $TemporaryFile.DirectoryName -localFile $TemporaryFile.Name
    }
    else {
        throw "Platform $PlatformId not found in Policies.xml"
    }
    Close-PVSafe -safe PVWAConfig

    return $PoliciesXml
}