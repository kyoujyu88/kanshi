# Main.ps1
$InputFile = ".\users.csv"
# 今日の日付のログファイルを作ります（例：Log_20260227.csv）
$LogFile = ".\Log_$(Get-Date -Format 'yyyyMMdd').csv"

Write-Host "--- 勤怠ハイブリッド監視を開始します ---" -ForegroundColor Cyan

# 名簿の読み込み
$Users = Import-Csv -Path $InputFile -Encoding UTF8

# 初めてファイルを作る時は、一番上にタイトルを書きます
if (-not (Test-Path $LogFile)) {
    "チェック時刻,ユーザーID,IPアドレス,AD出勤時間,現在の状態" | Add-Content -Path $LogFile -Encoding UTF8
}

# ずっと監視を続けるループです（5分おき）
while ($true) {
    $Now = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Now] チェックしています..." -ForegroundColor Yellow

    foreach ($User in $Users) {
        # 1. AD担当（Check-AD.ps1）にお願いして出勤時間をもらいます
        $LogonTime = .\Check-AD.ps1 -UserName $User.UserName
        $LogonStr = if ($LogonTime) { $LogonTime.ToString("yyyy/MM/dd HH:mm:ss") } else { "記録なし" }

        # 2. Ping担当（Check-Ping.ps1）にお願いして今の状態をもらいます
        $IsAlive = .\Check-Ping.ps1 -IPAddress $User.IPAddress
        $PingStr = if ($IsAlive) { "稼働中" } else { "停止(退勤)" }

        # 3. 結果を合体させて、CSVファイルに書き込みます
        $Line = "$Now,$($User.UserName),$($User.IPAddress),$LogonStr,$PingStr"
        Add-Content -Path $LogFile -Value $Line -Encoding UTF8

        # 画面にも優しく表示します
        $Color = if ($IsAlive) { "Green" } else { "Gray" }
        Write-Host " -> $($User.UserName)さん : 出勤[$LogonStr] / 状態[$PingStr]" -ForegroundColor $Color
    }
    
    Write-Host "次のチェックまで5分待機します..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 300
}
