# Check-Ping.ps1
param (
    [Parameter(Mandatory=$true)]
    [string]$IPAddress
)

try {
    # 1. まずはPingで確認します
    if (Test-Connection -ComputerName $IPAddress -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        return $true # 稼働中！
    }

    # 2. PingがダメならARPで確認します
    $Neighbor = Get-NetNeighbor -IPAddress $IPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($Neighbor -and ($Neighbor.State -eq "Reachable" -or $Neighbor.State -eq "Stale")) {
        return $true # 稼働中！
    }
} catch {
    # エラーの時は何もしません
}

return $false # 停止（退勤）
