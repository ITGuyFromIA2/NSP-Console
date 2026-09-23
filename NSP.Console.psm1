# One function per file. Public commands are the only exported surface.
$public = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1')
foreach ($file in $public) {
    try { . $file.FullName }
    catch { throw "NSP.Console: failed to load $($file.Name): $_" }
}
Export-ModuleMember -Function $public.BaseName
