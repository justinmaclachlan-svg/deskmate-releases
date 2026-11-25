# Creates a Deskmate OS virtual machine in Hyper-V and ties it to Deskmate on this PC.
#
# Run in PowerShell as Administrator (Windows 10/11 Pro, Enterprise or Education
# with Hyper-V turned on):
#
#   irm https://github.com/justinmaclachlan-svg/deskmate-releases/raw/main/New-DeskmateVM.ps1 -OutFile New-DeskmateVM.ps1
#   .\New-DeskmateVM.ps1
#
# It downloads the disk image, asks for your login name and passwords, makes a
# generation 2 VM, and (when Deskmate is installed here) adds the VM to
# Deskmate's Machines so your Bots on this PC can work inside it.

param(
    [string]$Name = "Deskmate OS",
    [int]$MemoryGB = 6,
    [int]$Cpus = 4,
    [int]$DiskGB = 64,
    [string]$Folder = "$env:PUBLIC\Documents\Hyper-V\Deskmate OS",
    [string]$Source = "https://github.com/justinmaclachlan-svg/deskmate-releases/releases/download/os",
    # Use a DeskmateOS.vhdx you already have instead of downloading.
    [string]$Vhdx = "",
    # Start the VM with a fresh Deskmate instead of a clone of this PC's.
    [switch]$NoClone
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Say($t) { Write-Host $t -ForegroundColor Cyan }

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this in PowerShell as Administrator."
}
if (-not (Get-Command New-VM -ErrorAction SilentlyContinue)) {
    throw "Hyper-V isn't turned on. Turn on 'Hyper-V' in Windows Features (Pro, Enterprise or Education), restart, and run this again."
}
if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
    throw "A VM called '$Name' already exists. Remove it in Hyper-V Manager, or run this with -Name 'Another name'."
}

New-Item -ItemType Directory -Force -Path $Folder | Out-Null
$disk = Join-Path $Folder "$Name.vhdx"

if ($Vhdx) {
    Copy-Item $Vhdx $disk
} else {
    Say "Downloading Deskmate OS (1 to 2 GB; this takes a while)..."
    $zip = Join-Path $Folder "DeskmateOS.tar.xz"
    function Get-File($url, $to) {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -L --fail --retry 3 -# -o $to $url
            if ($LASTEXITCODE -ne 0) { throw "Couldn't download $url" }
        } else { Invoke-WebRequest $url -OutFile $to -UseBasicParsing }
    }
    $parts = (Invoke-WebRequest "$Source/parts.txt" -UseBasicParsing).Content -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $want = ([string](Invoke-WebRequest "$Source/DeskmateOS.tar.xz.sha256" -UseBasicParsing).Content).Trim()
    $out = [IO.File]::Create($zip)
    try {
        $i = 0
        foreach ($p in $parts) {
            $i++
            Write-Host "  part $i of $($parts.Count)"
            $tmp = "$zip.part"
            Get-File "$Source/$p" $tmp
            $in = [IO.File]::OpenRead($tmp)
            try { $in.CopyTo($out) } finally { $in.Close() }
            Remove-Item $tmp
        }
    } finally { $out.Close() }
    $got = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($got -ne $want.ToLower()) { throw "The download is damaged (checksum doesn't match). Run this again." }
    Say "Unpacking..."
    & tar.exe -xf $zip -C $Folder
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $Folder "DeskmateOS.vhdx"))) {
        throw "Couldn't unpack the download with Windows' tar. Unpack $zip with 7-Zip, then run this again with -Vhdx <path to DeskmateOS.vhdx>."
    }
    Move-Item (Join-Path $Folder "DeskmateOS.vhdx") $disk
    Remove-Item $zip
}

# The download may carry "sparse" or "compressed" marks that Hyper-V refuses.
fsutil sparse setflag "$disk" 0 | Out-Null
compact /U "$disk" | Out-Null
Resize-VHD -Path $disk -SizeBytes ($DiskGB * 1GB)

# Who you'll be inside the VM.
Say "Set up your login inside Deskmate OS."
do { $user = (Read-Host "Login name (lowercase letters and digits, like '$($env:USERNAME.ToLower() -replace '[^a-z0-9]','')')").Trim().ToLower() } until ($user -match '^[a-z][a-z0-9_-]{0,23}$' -and $user -ne 'root' -and $user -notlike '*-bots')
function Ask-Password($what) {
    while ($true) {
        $a = Read-Host "$what" -AsSecureString
        $b = Read-Host "Again" -AsSecureString
        $pa = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($a))
        $pb = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($b))
        if ($pa -eq $pb -and $pa.Length -ge 4 -and $pa -notmatch "[`r`n]") { return $pa }
        Write-Host "They didn't match, or it was under 4 characters. Try again." -ForegroundColor Yellow
    }
}
$userPw = Ask-Password "Password for $user"
$rootPw = Ask-Password "Password for root (terminal only; Bots never run as root)"

# Deskmate on this PC reaches the VM's Bots' account with its own SSH key.
$hostKey = ""
$keyFile = Join-Path $env:APPDATA "Deskmate\machines\id_ed25519.pub"
if (-not (Test-Path $keyFile)) {
    $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
    if ($sshKeygen -and (Test-Path (Join-Path $env:APPDATA "Deskmate"))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $keyFile) | Out-Null
        & ssh-keygen -t ed25519 -N '""' -C deskmate -q -f ($keyFile -replace '\.pub$', '')
    }
}
if (Test-Path $keyFile) { $hostKey = (Get-Content $keyFile -Raw).Trim() }

# Clone Deskmate from this PC: Bots (names, looks, models, personas, memory),
# skills, plugins, teams, routines and policy rules. Never sign-ins, saved
# secrets, browser logins or chat history: the VM signs in for itself.
$cloneFile = ""
# dm.exe comes with Deskmate for Windows; it may not be on the PATH.
if (-not (Get-Command dm -ErrorAction SilentlyContinue)) {
    foreach ($d in @("$env:ProgramFiles\Deskmate", "$env:LOCALAPPDATA\Programs\Deskmate", "$env:LOCALAPPDATA\Deskmate")) {
        if (Test-Path (Join-Path $d "dm.exe")) { $env:PATH = "$d;$env:PATH"; break }
    }
}
$dmCmd = Get-Command dm -ErrorAction SilentlyContinue
if ($dmCmd -and -not $NoClone) {
    $try = Join-Path $Folder "deskmate-clone.bin"
    try {
        Push-Location $Folder
        $line = & dm clone export "deskmate-clone.bin" 2>&1
        Pop-Location
        if ($LASTEXITCODE -eq 0 -and (Test-Path $try) -and (Get-Item $try).Length -lt 200MB) {
            $cloneFile = $try
            Say "Cloning Deskmate from this PC: $line"
        } else {
            Write-Host "Couldn't clone Deskmate from this PC ($line). Open Deskmate here first, then run: dm clone export file.bin  and, in the VM, dm clone import file.bin" -ForegroundColor Yellow
        }
    } catch { Pop-Location; Write-Host "Couldn't clone Deskmate from this PC: $($_.Exception.Message)" -ForegroundColor Yellow }
} elseif (-not $NoClone) {
    Write-Host "Deskmate isn't installed on this PC (or 'dm' isn't on the PATH), so the VM starts with a fresh Deskmate." -ForegroundColor Yellow
}

# Leave the answers on the VM's small boot partition; first start reads them
# and then erases the file.
$seeded = $false
try {
    $mounted = Mount-VHD -Path $disk -Passthru
    $esp = Get-Partition -DiskNumber $mounted.DiskNumber | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1
    $mp = Join-Path $Folder "esp"
    New-Item -ItemType Directory -Force -Path $mp | Out-Null
    Add-PartitionAccessPath -DiskNumber $mounted.DiskNumber -PartitionNumber $esp.PartitionNumber -AccessPath $mp
    $vmHost = ($Name -replace '[^A-Za-z0-9-]', '-').ToLower()
    $conf = "HOSTNAME=$vmHost`nADMIN_USER=$user`nADMIN_PASSWORD=$userPw`nROOT_PASSWORD=$rootPw`nHOST_SSH_KEY=$hostKey`n"
    [IO.File]::WriteAllText((Join-Path $mp "deskmate-setup.conf"), $conf, (New-Object Text.UTF8Encoding $false))
    if ($cloneFile) { Copy-Item $cloneFile (Join-Path $mp "deskmate-clone.bin") }
    Remove-PartitionAccessPath -DiskNumber $mounted.DiskNumber -PartitionNumber $esp.PartitionNumber -AccessPath $mp
    Remove-Item $mp -Force
    $seeded = $true
} catch {
    Write-Host "Couldn't save your answers into the disk ($($_.Exception.Message)). Deskmate OS will ask for them on its first start instead." -ForegroundColor Yellow
} finally {
    Dismount-VHD -Path $disk -ErrorAction SilentlyContinue
}
if ($cloneFile) { Remove-Item $cloneFile -Force -ErrorAction SilentlyContinue }
$userPw = $null; $rootPw = $null

Say "Creating the VM..."
$switch = (Get-VMSwitch | Where-Object { $_.Name -eq "Default Switch" } | Select-Object -First 1)
if (-not $switch) { $switch = Get-VMSwitch | Select-Object -First 1 }
$vm = New-VM -Name $Name -Generation 2 -MemoryStartupBytes ($MemoryGB * 1GB) -VHDPath $disk -Path $Folder
if ($switch) { Connect-VMNetworkAdapter -VMName $Name -SwitchName $switch.Name }
Set-VMProcessor -VMName $Name -Count $Cpus
Set-VMMemory -VMName $Name -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes ($MemoryGB * 1GB) -MaximumBytes ($MemoryGB * 1GB)
# Debian's boot loader is signed for Secure Boot with Microsoft's key for other systems.
Set-VMFirmware -VMName $Name -EnableSecureBoot On -SecureBootTemplate MicrosoftUEFICertificateAuthority
Set-VM -Name $Name -AutomaticCheckpointsEnabled $false -CheckpointType Production
try { Set-VMVideo -VMName $Name -HorizontalResolution 1920 -VerticalResolution 1080 -ResolutionType Single } catch {}
Enable-VMIntegrationService -VMName $Name -Name "Guest Service Interface" -ErrorAction SilentlyContinue
# A way back: go to this point any time with Hyper-V Manager > Checkpoints.
Checkpoint-VM -Name $Name -SnapshotName "Fresh install"
Start-VM -Name $Name

# Add it to Deskmate's Machines on this PC, so Bots here can work inside it.
$dm = Get-Command dm -ErrorAction SilentlyContinue
if ($dm -and $hostKey -and $seeded) {
    $machine = @{ machine = @{ name = ($Name -replace '[^A-Za-z0-9]', '-').ToLower(); kind = "hyperv"; keep = "always"; everyone = $true; options = @{ vm = $Name; os = "linux"; user = "$user-bots" } } } | ConvertTo-Json -Depth 5 -Compress
    try {
        # Windows PowerShell drops bare double quotes on the way to a program.
        & dm call machines.create ($machine -replace '"', '\"') | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "dm failed" }
        Say "Added '$Name' to Deskmate's Machines. Bots on this PC can use it with machine_use."
    } catch {
        Write-Host "Couldn't add it to Deskmate automatically. In Deskmate: Settings > Machines > Add > Hyper-V VM, VM name '$Name', user '$user-bots'." -ForegroundColor Yellow
    }
} else {
    Write-Host "To let Bots on this PC use the VM: in Deskmate, Settings > Machines > Add > Hyper-V VM, VM name '$Name', OS linux, user '$user-bots'. Then, inside the VM, run: sudo deskmate-os host-key ""<the key Deskmate shows under Machines>""" -ForegroundColor Yellow
}

Say "Done. The VM is starting; a window opens now."
if ($cloneFile) { Write-Host "Your Bots, skills and tools were cloned in. Sign-ins weren't: in the VM's terminal run  deskmate-os login claude  (and codex, gemini)." }
Write-Host "Log in as $user. Deskmate fills the screen; the top-right corner switches to the normal Linux desktop and back."
Write-Host "If it stops at a 'Secure Boot' error: turn the VM off, then run  Set-VMFirmware -VMName '$Name' -EnableSecureBoot Off  and start it again."
vmconnect.exe localhost "$Name"
