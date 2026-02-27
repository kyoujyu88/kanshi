# --- 設定エリア ---
# 調べたい人のログインID（Windowsにログインする時の名前）を入れてください
$TargetUser = "Atsushi" # ← まずはご自身のIDで試してみてくださいね！

Write-Host "--- Active Directory に問い合わせ中... ---" -ForegroundColor Cyan

try {
    # 1. [adsisearcher] という魔法の言葉で、ADの案内所に検索をお願いします
    $Searcher = [adsisearcher]"(&(objectCategory=user)(sAMAccountName=$TargetUser))"
    
    # 2. 検索結果を1件だけ受け取ります
    $Result = $Searcher.FindOne()

    if ($Result) {
        $UserProps = $Result.Properties
        
        # 3. ADの中に記録されている「最後にログオンした時間 (lastlogon)」を取り出します
        # ※ADの時間は「1601年からの経過時間」という特殊な数字なので、私たちが読める日時に変換します
        if ($UserProps.lastlogon) {
            $LogonTime = [datetime]::FromFileTime($UserProps.lastlogon[0])
            
            Write-Host "【結果が見つかりました！】" -ForegroundColor Green
            Write-Host "ユーザーID : $TargetUser"
            Write-Host "お名前     : $($UserProps.displayname)"
            Write-Host "最終ログオン: $LogonTime"
        } else {
            Write-Host "ユーザーはいますが、まだ一度もログインしていないようです。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "案内所に '$TargetUser' というユーザーは見つかりませんでした..." -ForegroundColor Red
    }
} catch {
    Write-Host "エラーが発生しました..." -ForegroundColor Red
    Write-Host "ADにアクセスできない環境か、ドメインに繋がっていないかもしれません。"
}
