
$ThisPS1 = $MyInvocation.MyCommand
Function Help
{
    echo "Usage:"
    echo "   $ThisPS1 # run bash in mintty directly"
    echo "   $ThisPS1 <bin> [parameters] # run bin in mintty"
    echo "   $ThisPS1 --add|-a <bin> [parameters] # add a ps1 script to wrap bin run with mintty"
    echo "   $ThisPS1 --rmove|-r <bin> # remove a ps1 script"
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
        New-Item -ItemType directory -Path $SHIMDIR
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

    $minttyPS1 = $(Resolve-Path $PSCommandPath)
    If ($args.count -ge 3)
    {
        $param = $args[2 .. ($args.count - 1)]
        $outputPS1_content = "$minttyPS1 $bin $param"
    }
    Else
    {
        $outputPS1_content = "$minttyPS1 $bin" + ' "$args"'
    }

    $outputPS1_path = "$SHIMDIR\$name" + ".ps1"

    echo $outputPS1_content | Out-File $outputPS1_path utf8
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
    add-Path "$msys_bin_path"
    $env:MSYSTEM = "MINGW32"
    If ($args.count -ge 1)
    {
        $command = "/bin/bash -c '$args; echo Exited by " + '$?' + ". Press enter to continue; read;'"
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
