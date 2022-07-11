BeforeAll {
    Import-Module $PSScriptRoot\..\Deploy-PASExtensions\Deploy-PASExtensions.psd1 -Force

    Mock -CommandName Open-PVSafe -ModuleName Deploy-PASExtensions
    Mock -CommandName Add-PVFile -ModuleName Deploy-PASExtensions
    Mock -CommandName Close-PVSafe -ModuleName Deploy-PASExtensions
}

Describe 'Update-PoliciesXml' {
    BeforeAll {
        Mock -CommandName Get-PVFile -ModuleName Deploy-PASExtensions
        Mock -CommandName Get-Content -ParameterFilter { $Path -like '*.tmp' } -MockWith { return (Get-Content -Path 'Tests\Policies.xml') } -ModuleName Deploy-PASExtensions

    }
    It 'validates that the platform exists in Policies.xml' {
        { Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceMode' } | Should -Not -Throw 'Platform RealVNCServiceMode not found in Policies.xml'

        { Update-PoliciesXml -PVWASettingsFile 'Tests\Policy-RealVNCServiceMode.xml' -PlatformId 'RealVNCServiceModeNotExisting' } | Should -Throw 'Platform RealVNCServiceModeNotExisting not found in Policies.xml'
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
        } -ModuleName Deploy-PASExtensions
    }
}