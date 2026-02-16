# --- 設定エリア ---
# 調べたい相手のIPアドレス（まずは自分のIPで試すのがオススメです！）
$TargetIP = "192.168.1.10" 

# エラーが出てもスクリプトを止めないおまじない
$ErrorActionPreference = "Stop"

try {
    Write-Host "--- $TargetIP の診断を開始します ---" -ForegroundColor Cyan

    # 1. OSの情報（起動時間など）を取得
    #    Win32_OperatingSystem は「Windowsの基本情報」を持っています
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $TargetIP

    # 2. コンピュータシステムの情報（機種名、ログインユーザー）を取得
    #    Win32_ComputerSystem は「ハードウェアとユーザー」の情報を持っています
    $Sys = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $TargetIP

    # --- データの加工（見やすくします） ---
    
    # 稼働時間（Uptime）を計算
    $Uptime = New-TimeSpan -Start $OS.LastBootUpTime -End (Get-Date)
    $UptimeText = "{0}日 {1}時間 {2}分" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes

    # 結果をまとめて表示
    $Result = [PSCustomObject]@{
        'PC名'        = $Sys.DNSHostName
        'メーカー'    = $Sys.Manufacturer
        '機種名'      = $Sys.Model             # ここに PC-VKL45EZGM とかが出ます！
        'OS'          = $OS.Caption
        '最終起動日時'= $OS.LastBootUpTime
        '稼働時間'    = $UptimeText            # これが勤怠管理に使えます！
        'ログイン中'  = $Sys.UserName          # 誰が使っているか
    }

    # 表形式で見やすく出力
    $Result | Format-List

} catch {
    # 失敗した時のメッセージ
    Write-Host "診断に失敗しました..." -ForegroundColor Red
    Write-Host "エラー内容: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "※ 原因: ファイアウォールでブロックされているか、管理者権限がない可能性があります。" -ForegroundColor Gray
}
