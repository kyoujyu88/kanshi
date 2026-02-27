# Check-AD.ps1
param (
    [Parameter(Mandatory=$true)]
    [string]$UserName
)

try {
    # ADの案内所に検索をお願いします
    $Searcher = [adsisearcher]"(&(objectCategory=user)(sAMAccountName=$UserName))"
    $Result = $Searcher.FindOne()

    # 見つかったら、時間を変換してお返しします
    if ($Result -and $Result.Properties.lastlogon) {
        $LogonTime = [datetime]::FromFileTime($Result.Properties.lastlogon[0])
        return $LogonTime
    }
} catch {
    # エラーの時は何もしません
}

# 見つからなかったら空っぽ（$null）をお返しします
return $null
