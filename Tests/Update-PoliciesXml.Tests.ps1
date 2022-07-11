BeforeAll {
    # . $PSScriptRoot\..\Deploy-PASExtensions\Functions\Update-PASPlatformFiles.ps1
    Import-Module -Name "$PSScriptRoot\..\Deploy-PASExtensions\Deploy-PASExtensions.psd1"

    Mock -CommandName Open-PVSafe
    Mock -CommandName Add-PVFile
    Mock -CommandName Close-PVSafe

}

Describe 'Update-PoliciesXml' {
    BeforeAll {
        Mock -CommandName Get-PVFile
        Mock -CommandName Get-Content -ParameterFilter {$Path -like '*.tmp' } -MockWith { return (Get-Content -Path 'Tests\Policies.xml') }

    }
    It 'validates that the platform exists in Policies.xml' {
        { Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceMode' } | Should -Not -throw "Platform RealVNCServiceMode not found in Policies.xml"

        { Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceModeNotExisting' } | Should -throw "Platform RealVNCServiceModeNotExisting not found in Policies.xml"
    }

    It 'replaces the platform content in Policies.xml with the content in the PVWA settings file' {
        $PoliciesXml = Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceMode'
        (Select-Xml -Xml $PoliciesXml -XPath '//*[@ID="RealVNCServiceMode"]/Properties/Optional/Property[@Name="Banana"]')[0] | Should -Be $true
    }

    It 'adds the new Policies.xml to the Vault' {
        Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceMode'

        Should -Invoke -CommandName Add-PVFile -ParameterFilter {
            $safe -eq 'PVWAConfig' -and
            $folder -eq 'root' -and
            $file -eq 'Policies.xml'
        }
    }
}