# --- 設定エリア ---
$InputFile = ".\device_list.txt"       # IPリスト
$OutputFile = ".\attendance_log.csv"   # ログ保存先
$CheckInterval = 300                   # 監視間隔（秒）。テスト時は 10 とかにするとすぐ動きます！

# --------------------------
# 1. 画面の準備
# --------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# メインウィンドウ
$form = New-Object System.Windows.Forms.Form
$form.Text = "JGSDF Attendance Monitor"  # かっこよく英語にしてみました
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# 結果を表示する大きなテキストボックス
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 20)
$logBox.Size = New-Object System.Drawing.Size(440, 250)
$logBox.Multiline = $true            # 複数行書けるようにする
$logBox.ScrollBars = "Vertical"      # スクロールバーをつける
$logBox.ReadOnly = $true             # ユーザーが書き換えられないようにする
$form.Controls.Add($logBox)

# スタートボタン
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "監視開始 (Start)"
$btnStart.Location = New-Object System.Drawing.Point(50, 300)
$btnStart.Size = New-Object System.Drawing.Size(120, 40)
$form.Controls.Add($btnStart)

# ストップボタン
$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "停止 (Stop)"
$btnStop.Location = New-Object System.Drawing.Point(180, 300)
$btnStop.Size = New-Object System.Drawing.Size(120, 40)
$btnStop.Enabled = $false  # 最初は押せないようにしておく
$form.Controls.Add($btnStop)

# --------------------------
# 2. 監視ロジック（タイマーの中身）
# --------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $CheckInterval * 1000  # ミリ秒単位なので1000倍します

# タイマーが鳴った時の処理（ここが心臓部です！）
$action = {
    $Now = Get-Date -Format "HH:mm:ss"
    
    # 画面に「確認中...」と出す
    $logBox.AppendText("[$Now] チェック中..." + [Environment]::NewLine)
    
    # IPリストの読み込み
    if (Test-Path $InputFile) {
        $TargetIPs = Get-Content $InputFile
    } else {
        $logBox.AppendText("エラー: device_list.txt がありません！" + [Environment]::NewLine)
        return
    }

    foreach ($IP in $TargetIPs) {
        if ([string]::IsNullOrWhiteSpace($IP)) { continue }

        # Ping & ARPチェック
        try {
            Test-Connection -ComputerName $IP -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null
        } catch {}
        
        $Neighbor = Get-NetNeighbor -IPAddress $IP -AddressFamily IPv4 -ErrorAction SilentlyContinue
        
        $Status = "停止"
        if ($Neighbor -and ($Neighbor.State -eq "Reachable" -or $Neighbor.State -eq "Stale")) {
            $Status = "稼働中"
        }

        # ログ作成
        $LogLine = "$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss'),$IP,$Status"
        
        # CSV保存
        Add-Content -Path $OutputFile -Value $LogLine -Encoding UTF8

        # 画面にも表示
        $logBox.AppendText(" -> $IP : $Status" + [Environment]::NewLine)
    }
    
    $logBox.AppendText("------------------------" + [Environment]::NewLine)
}

# --------------------------
# 3. ボタンを押した時の動き
# --------------------------

# スタートボタンを押した時
$btnStart.Add_Click({
    $btnStart.Enabled = $false
    $btnStop.Enabled = $true
    $logBox.AppendText("--- 監視を開始します ---" + [Environment]::NewLine)
    
    # すぐに1回実行してから、タイマーを動かす
    & $action
    $timer.Start()
})

# ストップボタンを押した時
$btnStop.Add_Click({
    $timer.Stop()
    $btnStart.Enabled = $true
    $btnStop.Enabled = $false
    $logBox.AppendText("--- 監視を停止しました ---" + [Environment]::NewLine)
})

# タイマーに処理を登録
$timer.Add_Tick($action)

# --------------------------
# 4. 実行！
# --------------------------
$form.ShowDialog()
