BeforeAll {
    Import-Module $PSScriptRoot\..\Deploy-PASExtensions\Deploy-PASExtensions.psd1

    Mock -CommandName Open-PVSafe -ModuleName Deploy-PASExtensions
    Mock -CommandName Add-PVFile -ModuleName Deploy-PASExtensions
    Mock -CommandName Close-PVSafe -ModuleName Deploy-PASExtensions

}

Describe 'Update-PASPlatformFiles' {
    BeforeAll {
        Mock -CommandName Update-PoliciesXml -ModuleName Deploy-PASExtensions
        Mock -CommandName Get-PVFile -ModuleName Deploy-PASExtensions

        Mock -CommandName Find-PVFile -MockWith { $true } -ModuleName Deploy-PASExtensions
        Mock -CommandName Get-PVFolder -MockWith { return [PSCustomObject]@{
                Folder = "Root\ImportedPlatforms\Policy-$PlatformId"
            }
        } -ModuleName Deploy-PASExtensions

        # Create a dummy platform and structure for the test
        $PlatformId = 'SamplePlatform'
        $PlatformDirectory = New-Item -Path (Join-Path -Path $TestDrive -ChildPath $PlatformId) -ItemType Directory
        # Create the required parts of a platform
        $PlatformCPMPolicyFile = Join-Path -Path $PlatformDirectory -ChildPath "Policy-$PlatformId.ini"
        Out-File -FilePath $PlatformCPMPolicyFile -Force
        $PlatformPVWASettingsFile = Join-Path -Path $PlatformDirectory -ChildPath "Policy-$PlatformId.xml"
        Out-File -FilePath $PlatformPVWASettingsFile -Force
        # Optional files
        Out-File -FilePath (Join-Path -Path $PlatformDirectory -ChildPath "$($PlatformId)Process.ini") -Force
        Out-File -FilePath (Join-Path -Path $PlatformDirectory -ChildPath "$($PlatformId)Prompts.ini") -Force

    }
    It 'assumes the PlatformID based on the directory name' {
        Update-PASPlatformFiles -Path $PlatformDirectory

        Should -Invoke -CommandName Add-PVFile -ParameterFilter {
            $safe -eq 'PasswordManagerShared' -and
            $folder -eq 'root\Policies' -and
            $file -eq "Policy-$PlatformId.ini" -and
            $localFolder -eq $PlatformDirectory -and
            $localFile -eq "Policy-$PlatformId.ini"
        } -ModuleName Deploy-PASExtensions
    }

    It 'takes a list of platform folders and updates the files' {
        # Create a second dummy platform and structure for the test
        $PlatformId2 = 'SamplePlatform2'
        $PlatformDirectory2 = New-Item -Path (Join-Path -Path $TestDrive -ChildPath $PlatformId2) -ItemType Directory
        # Create the required parts of a platform
        $PlatformCPMPolicyFile2 = Join-Path -Path $PlatformDirectory2 -ChildPath "Policy-$PlatformId2.ini"
        Out-File -FilePath $PlatformCPMPolicyFile2 -Force
        $PlatformPVWASettingsFile2 = Join-Path -Path $PlatformDirectory2 -ChildPath "Policy-$PlatformId2.xml"
        Out-File -FilePath $PlatformPVWASettingsFile2 -Force

        (Get-ChildItem $TestDrive).FullName | Update-PASPlatformFiles

        Should -Invoke -CommandName Add-PVFile -ParameterFilter {
            $safe -eq 'PasswordManagerShared' -and
            $folder -eq 'root\Policies' -and
            $file -eq "Policy-$PlatformId.ini" -and
            $localFolder -eq $PlatformDirectory -and
            $localFile -eq "Policy-$PlatformId.ini"
        } -ModuleName Deploy-PASExtensions

        Should -Invoke -CommandName Add-PVFile -ParameterFilter {
            $safe -eq 'PasswordManagerShared' -and
            $folder -eq 'root\Policies' -and
            $file -eq "Policy-$PlatformId2.ini" -and
            $localFolder -eq $PlatformDirectory2 -and
            $localFile -eq "Policy-$PlatformId2.ini"
        } -ModuleName Deploy-PASExtensions
    }

    It 'writes an error if the platform is not found in the Vault' {
        Mock -CommandName Find-PVFile -MockWith { $null } -ModuleName Deploy-PASExtensions

        { Update-PASPlatformFiles -PlatformId banana -Path $PlatformDirectory } | Should -throw "Platform banana not found in Vault. Aborting."
    }

    Context 'when updating existing platforms' {

        It 'must add the CPM policy file to the Vault' {
            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq 'root\Policies' -and
                $file -eq "Policy-$PlatformId.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "Policy-$PlatformId.ini"
            } -ModuleName Deploy-PASExtensions
        }
        It 'must add any optional files to the Vault' {
            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "$($PlatformId)Process.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "$($PlatformId)Process.ini"
            } -ModuleName Deploy-PASExtensions

            Should -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "$($PlatformId)Prompts.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "$($PlatformId)Prompts.ini"
            } -ModuleName Deploy-PASExtensions
        }

        It 'does not add the CPM policy file to the platform folder under ImportedPlatforms' {
            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Not -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "Policy-$PlatformId.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "Policy-$PlatformId.ini"
            } -ModuleName Deploy-PASExtensions
        }

        It 'does not add the PVWA config file to the platform folder under ImportedPlatforms' {
            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Not -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "Policy-$PlatformId.xml" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "Policy-$PlatformId.xml"
            } -ModuleName Deploy-PASExtensions
        }

        It 'does not add optional files to the Vault if the platform was not imported' {
            Mock -CommandName Get-PVFolder -MockWith { $null } -ModuleName Deploy-PASExtensions
            Mock -CommandName Write-Warning -ModuleName Deploy-PASExtensions

            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Not -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "$($PlatformId)Process.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "$($PlatformId)Process.ini"
            } -ModuleName Deploy-PASExtensions

            Should -Not -Invoke -CommandName Add-PVFile -ParameterFilter {
                $safe -eq 'PasswordManagerShared' -and
                $folder -eq "root\ImportedPlatforms\Policy-$PlatformId" -and
                $file -eq "$($PlatformId)Prompts.ini" -and
                $localFolder -eq $PlatformDirectory -and
                $localFile -eq "$($PlatformId)Prompts.ini"
            } -ModuleName Deploy-PASExtensions

            Should -Invoke -CommandName Write-Warning -ModuleName Deploy-PASExtensions
        }

        It 'must merge the PVWA settings file into Policies.xml' {
            Update-PASPlatformFiles -PlatformId $PlatformId -Path $PlatformDirectory

            Should -Invoke -CommandName Update-PoliciesXml -ParameterFilter {
                $PVWASettingsFile -eq $PlatformPVWASettingsFile -and
                $PesterBoundParameters.PlatformId -eq $PlatformId
            } -ModuleName Deploy-PASExtensions

        }
    }
}