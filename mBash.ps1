
$options = @()
$params = [System.Collections.Generic.List[System.Object]]($args)
While ("$params[0]".StartsWith("-")){
    $options += $params[0].ToLower()
    $params.RemoveAt(0)
}

$ThisPS1 = $MyInvocation.MyCommand
$ShimDir = "$PSScriptRoot\shim"

$Ret = $true

Function CygPath
{
    $r = [Regex]::Replace($args[0], '^(\w):', { param($m) '/' + $m.Groups[1].Value.ToLower() })
    $r = [Regex]::Replace($r, '\\+', '/')
    return $r
}

Function MkShimDir
{
    if(!(Test-Path -Path $ShimDir )){
        New-Item -ItemType directory -Path $ShimDir | Out-Null
    }
}

Function BakShimDir
{
    if(Test-Path -Path $ShimDir){
        mv $ShimDir "${ShimDir}_bak_$(Get-Date -format "yyyyMMddHHmm")"
    }
}

Function Help
{
    echo "Usage:"
    echo "   $ThisPS1 {Opts} # run msys Bash directly"
    echo "   $ThisPS1 {Opts} <bin> [parameters] # run exe/script using msys Bash"
    echo "   $ThisPS1 -add|-a {Opts} <name> <bin> [parameters] # add a shortcut to run bin using msys Bash"
    echo "   $ThisPS1 -rmove|-r <name> # remove a shortcut"
    echo "   $ThisPS1 -backup [dir] # backup shortcuts config dir"
    echo "   $ThisPS1 -restore [dir] # restore shortcuts config dir"
    echo "   $ThisPS1 -link [dir] # link shortcuts config dir"
    echo "   $ThisPS1 -help|-h # show this help"
    echo ""
    echo "Flags and Options {Opts}:"
    echo "   -mintty|-m: Use mintty externally instead of current window"
    echo "   -cygpath|-p: Detect paths in parameters and translate them into cygwin format"
    $Ret = $false
}

Function RunMbash($mintty, $cygpath)
{
    if(!$env:home) { $env:home = "$home\" }
    if($env:home -eq "\") { $env:home = $env:allusersprofile }

    $msys_path = scoop.cmd which msys "2>NUL"

    If ($msys_path){
        $env:_START_WD = $(pwd)
        $msys_bin_path = "$(Resolve-Path $(Split-Path $msys_path))\bin"
        $oriPath = $env:PATH
        $env:PATH = "$msys_bin_path;" + $env:PATH
        $env:PATH = $env:PATH.Replace($ShimDir,"")
        $env:MSYSTEM = "MINGW32"
        If ($params.count -ge 1){
            if(Test-Path $params[0]){
                $bin = CygPath $(Resolve-Path $params[0])
            }
            Else{
                $bin = $params[0]
            }

            If ($params.count -ge 2){
                $commandParams = $params[1 .. ($params.count - 1)]
                If ($cygpath){
                    $pa = @()
                    ForEach ($p in $commandParams){
                        if(Test-Path $p){
                            $pa += $(CygPath $(Resolve-Path $p))
                        }
                        Else{
                            $pa += $p
                        }
                    }
                    $commandParams = $pa
                }
                $bash_command = "$bin $commandParams"
            }
            Else{
                $bash_command = "$bin"
            }
            
            $extra = ""
            If ($mintty){
                $extra = "echo Exited by " + '$ret' + ". Press enter to continue; read;"
            }
            $command = "bash -c '$bash_command; ret=" + '$?' + "; $extra exit " + '$ret' + ";'"
        }
        Else{
            $command = "bash -l"
        }
        
        If ($mintty){
            start $msys_bin_path\mintty $command
            $Ret = 0
        }
        Else{
            Invoke-Expression $command
            $Ret = $LASTEXITCODE
        }

        $env:PATH = $oriPath
    }
    Else{
        echo "Please install msys by 'scoop install msys'"
    }
}

Function Add($mintty, $cygpath)
{
    MkShimDir

    If ($params.count -lt 2)
    {
        Help
        Return
    }

    if(Test-Path $params[0]){
        $bin = $(Resolve-Path $params[0])
    }
    Else
    {
        $bin = $params[0]
    }
    $name = $params[1]

    $outputPS1_content = "$bin"
    If ($params.count -ge 3)
    {
        $param = $param[2 .. ($param.count - 1)]
        $outputPS1_content = "$outputPS1_content $param"
    }
    $outputPS1_content = "$outputPS1_content" + ' "$args"'

    $options = ""
    If ($mintty){
        $options = "$options -mintty"
    }
    If ($cygpath){
        $options = "$options -cygpath"
    }

    $minttyPS1 = $(Resolve-Path $PSCommandPath)
    $outputPS1_path = "$ShimDir\$name" + ".ps1"
    echo "$minttyPS1 $options $outputPS1_content" | Out-File $outputPS1_path utf8
    echo "$outputPS1_path has been created!"
}

Function Remove
{
    If ($params.count -lt 1)
    {
        Help
        Return
    }

    $name = $params[0]
    $outputPS1_path = "$ShimDir\$name" + ".ps1"
    If(Test-Path $outputPS1_path){
        Remove-Item $outputPS1_path
        echo "$outputPS1_path has been removed!"
    }
    Else{
        echo "$outputPS1_path not exists!"
        $Ret = $false
    }
}

Function Backup
{
    If ($params.count -ge 1)
    {
        $target = $params[0]
    }
    Else
    {
        $target = "mBash-shim"
    }
    
    MkShimDir
    
    If (Test-Path $target)
    {
        mv $target "$target_old_$(Get-Date -format "yyyyMMddHHmm")"
    }

    cp -r $ShimDir $target
    echo "Copy $ShimDir => $target done!"
}

Function Restore
{
    If ($params.count -ge 1)
    {
        $target = $params[0]
    }
    Else
    {
        $target = $(pwd)
    }
    
    BakShimDir

    cp -r $target $ShimDir
    echo "Copy $target => $ShimDir done!"
}

Function Link
{
    If ($params.count -ge 1)
    {
        $target = $params[0]
    }
    Else
    {
        $target = $(pwd)
    }

    BakShimDir

    sudo cmd /c mklink /J $target $ShimDir
    echo "Copy $target => $ShimDir done!"
}

Function Main
{
    Param(
        # actions
        [switch] [alias("a")]
            $add,
        [switch] [alias("r")]
            $remove,
        [switch]
            $backup,
        [switch]
            $restore,
        [switch]
            $link,
        [switch] [alias("h")]
            $help,

        # opts
        [switch] [alias("m")]
            $mintty,
        [switch] [alias("p")]
            $cygpath
    )

    Switch ($TRUE)
    {
        Default { RunMbash $mintty $cygpath }
        $add { Add $mintty $cygpath }
        $remove { Remove }
        $backup { Backup }
        $restore { Restore }
        $link { Link }
        $help { Help }
    }
}

Invoke-Expression "Main $options"
Exit $Ret

