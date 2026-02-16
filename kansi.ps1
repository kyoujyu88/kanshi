# --- 設定エリア ---
$InputFile = ".\device_list.txt"       # IPリスト
$OutputFile = ".\attendance_log.csv"   # ログ保存先
$CheckInterval = 300                   # 監視間隔（秒）。テスト時は 10 くらいがおすすめ！

# --------------------------
# 1. 画面の準備
# --------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# メインウィンドウ
$form = New-Object System.Windows.Forms.Form
$form.Text = "JGSDF Attendance Monitor (Hybrid)"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# 結果を表示するテキストボックス
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 20)
$logBox.Size = New-Object System.Drawing.Size(440, 250)
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

# スタートボタン
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "監視開始"
$btnStart.Location = New-Object System.Drawing.Point(50, 300)
$btnStart.Size = New-Object System.Drawing.Size(120, 40)
$form.Controls.Add($btnStart)

# ストップボタン
$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "停止"
$btnStop.Location = New-Object System.Drawing.Point(180, 300)
$btnStop.Size = New-Object System.Drawing.Size(120, 40)
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

# --------------------------
# 2. 監視ロジック（改良版）
# --------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $CheckInterval * 1000

$action = {
    $Now = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$Now] チェック中..." + [Environment]::NewLine)
    
    if (Test-Path $InputFile) {
        $TargetIPs = Get-Content $InputFile
    } else {
        $logBox.AppendText("エラー: device_list.txt がありません！" + [Environment]::NewLine)
        return
    }

    foreach ($IP in $TargetIPs) {
        if ([string]::IsNullOrWhiteSpace($IP)) { continue }

        $Status = "停止"
        
        # --- ステップ1: まずはPingで確認（自分自身や普通のPC用） ---
        $PingSuccess = $false
        try {
            # Quietオプションで True/False だけ受け取ります
            $PingSuccess = Test-Connection -ComputerName $IP -Count 1 -Quiet -ErrorAction SilentlyContinue
        } catch {}

        if ($PingSuccess) {
            $Status = "稼働中 (Ping)"
        } 
        else {
            # --- ステップ2: PingダメならARPで確認（ブロックされたPC用） ---
            $Neighbor = Get-NetNeighbor -IPAddress $IP -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($Neighbor -and ($Neighbor.State -eq "Reachable" -or $Neighbor.State -eq "Stale")) {
                $Status = "稼働中 (ARP)"
            }
        }

        # ログ作成
        $LogLine = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss'),$IP,$Status"
        Add-Content -Path $OutputFile -Value $LogLine -Encoding UTF8
        $logBox.AppendText(" -> $IP : $Status" + [Environment]::NewLine)
    }
    
    $logBox.AppendText("------------------------" + [Environment]::NewLine)
}

# --------------------------
# 3. ボタン動作
# --------------------------
$btnStart.Add_Click({
    $btnStart.Enabled = $false
    $btnStop.Enabled = $true
    $logBox.AppendText("--- 監視を開始します ---" + [Environment]::NewLine)
    & $action
    $timer.Start()
})

$btnStop.Add_Click({
    $timer.Stop()
    $btnStart.Enabled = $true
    $btnStop.Enabled = $false
    $logBox.AppendText("--- 監視を停止しました ---" + [Environment]::NewLine)
})

$timer.Add_Tick($action)

# 実行
$form.ShowDialog()
