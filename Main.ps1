# Main.ps1
$InputFile = ".\users.csv"

# 1. 履歴を残す「日記」ファイル（どんどん追記されます）
$LogFile = ".\Log_$(Get-Date -Format 'yyyyMMdd').csv"

# 2. 今の状態がわかる「ホワイトボード」ファイル（毎回上書きされます）
$StatusFile = ".\CurrentStatus.csv"

Write-Host "--- 勤怠ハイブリッド監視を開始します ---" -ForegroundColor Cyan

# 名簿の読み込み
$Users = Import-Csv -Path $InputFile -Encoding UTF8

# 日記ファイルがなければ、最初にタイトルを書きます
if (-not (Test-Path $LogFile)) {
    "チェック時刻,ユーザーID,IPアドレス,AD出勤時間,現在の状態" | Add-Content -Path $LogFile -Encoding UTF8
}

# ずっと監視を続けるループです
while ($true) {
    $Now = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Now] チェックしています..." -ForegroundColor Yellow

    # 「今の状態」を一時的に入れておくための、空っぽの箱（配列）を用意します
    $CurrentStates = @()

    foreach ($User in $Users) {
        # AD担当にお願いして出勤時間をもらいます
        $LogonTime = .\Check-AD.ps1 -UserName $User.UserName
        $LogonStr = if ($LogonTime) { $LogonTime.ToString("yyyy/MM/dd HH:mm:ss") } else { "記録なし" }

        # Ping担当にお願いして今の状態をもらいます
        $IsAlive = .\Check-Ping.ps1 -IPAddress $User.IPAddress
        $PingStr = if ($IsAlive) { "稼働中" } else { "停止(退勤)" }

        # --- ① 履歴ログへの追記（今まで通り） ---
        $Line = "$Now,$($User.UserName),$($User.IPAddress),$LogonStr,$PingStr"
        Add-Content -Path $LogFile -Value $Line -Encoding UTF8

        # --- ② ホワイトボード用のデータ作成 ---
        # ユーザー一人ひとりの「今の状態」をキレイなデータにまとめます
        $StateObj = [PSCustomObject]@{
            '確認時刻'     = $Now
            'ユーザー名'   = $User.UserName
            'IPアドレス'   = $User.IPAddress
            '出勤時間(AD)' = $LogonStr
            '現在の状態'   = $PingStr
        }
        # まとめたデータを、さっきの箱に追加します
        $CurrentStates += $StateObj

        # 画面にも表示します
        $Color = if ($IsAlive) { "Green" } else { "Gray" }
        Write-Host " -> $($User.UserName)さん : 出勤[$LogonStr] / 状態[$PingStr]" -ForegroundColor $Color
    }
    
    # --- ③ ホワイトボードファイルの上書き保存 ---
    # 箱に貯まった全員分の最新状態を、CSVファイルとして「上書き」します
    $CurrentStates | Export-Csv -Path $StatusFile -Encoding UTF8 -NoTypeInformation

    Write-Host "--- 一覧表(CurrentStatus.csv)を更新しました ---" -ForegroundColor Cyan
    Write-Host "次のチェックまで5分待機します..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 300
}
