Get-ChildItem $PSScriptRoot\ -Recurse -Include "*.ps1" -Exclude "*.ps1xml" | %{
    . $_.FullName
}