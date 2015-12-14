
$ThisPS1 = $MyInvocation.MyCommand
Function Help
{
    echo "Usage:"
    echo "   $ThisPS1 # run bash in mintty directly"
    echo "   $ThisPS1 <bin> [parameters] # run bin in mintty"
    echo "   $ThisPS1 --add|-a <bin> [parameters] # add a ps1 script to wrap bin run with mintty"
    echo "   $ThisPS1 --rmove|-r <bin> # remove a ps1 script"
    echo "   $ThisPS1 --help|-h # show this help"
}

Function CygPath
{
    $r = [Regex]::Replace($args[0], '^(\w):', { param($m) '/' + $m.Groups[1].Value.ToLower() })
    $r = [Regex]::Replace($r, '\\+', '/')
    return $r
}

$SHIMDIR = "$PSScriptRoot\shim"
If ($args[0] -eq "-h" -Or $args[0] -eq "--help")
{
    Help
    exit
}
ElseIf ($args[0] -eq "-a" -Or $args[0] -eq "--add")
{
    if(!(Test-Path -Path $SHIMDIR )){
        New-Item -ItemType directory -Path $SHIMDIR | Out-Null
    }

    If ($args.count -lt 2)
    {
        Help
        exit 255
    }

    if(Test-Path $args[1]){
        $bin = $(Resolve-Path $args[1])
        $name = [io.path]::GetFileNameWithoutExtension($bin)
    }
    Else
    {
        $bin = $args[1]
        $name = $args[1]
    }

    If ($args.count -ge 3)
    {
        $param = $args[2 .. ($args.count - 1)]
        $outputPS1_content = "$bin $param"
    }
    Else
    {
        $outputPS1_content = "$bin" + ' "$args"'
    }

    $minttyPS1 = $(Resolve-Path $PSCommandPath)
    $outputPS1_path = "$SHIMDIR\$name" + ".ps1"
    echo "$minttyPS1 $outputPS1_content" | Out-File $outputPS1_path utf8
    echo "$outputPS1_path has been created!"
    exit
}
ElseIf ($args[0] -eq "-r" -Or $args[0] -eq "--remove")
{
    If ($args.count -lt 2)
    {
        Help
        exit 255
    }

    if(Test-Path $args[1]){
        $name = [io.path]::GetFileNameWithoutExtension($(Resolve-Path $args[1]))
    }
    Else
    {
        $name = $args[1]
    }
    $outputPS1_path = "$SHIMDIR\$name" + ".ps1"
    Remove-Item $outputPS1_path
    echo "$outputPS1_path has been removed!"
    exit
}

# Copy from scoop msys.ps1
if(!$env:home) { $env:home = "$home\" }
if($env:home -eq "\") { $env:home = $env:allusersprofile }

$msys_path = scoop.cmd which msys "2>NUL"

If ($msys_path)
{
    $env:_START_WD = $(pwd)
    $msys_bin_path = "$(Resolve-Path $(Split-Path $msys_path))\bin"
    $oriPath = $env:PATH
    $env:PATH = "$msys_bin_path;" + $env:PATH
    $env:MSYSTEM = "MINGW32"
    If ($args.count -ge 1)
    {
        if(Test-Path $args[0]){
            $bin = CygPath $(Resolve-Path $args[0])
        }
        Else
        {
            $bin = $args[0]
        }

        If ($args.count -ge 2)
        {
            $param = $args[1 .. ($args.count - 1)]
            $bash_command = "$bin $param"
        }
        Else
        {
            $bash_command = "$bin"
        }

        $command = "/bin/bash -c '$bash_command; echo Exited by " + '$?' + ". Press enter to continue; read;'"
    }
    Else
    {
        $command = "/bin/bash -l"
    }
    start $msys_bin_path\mintty $command
    $env:PATH = $oriPath
}
Else
{
    echo "Please install msys by 'scoop install msys'"
}
