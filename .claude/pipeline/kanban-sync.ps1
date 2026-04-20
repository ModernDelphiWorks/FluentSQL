$projectId = "PVT_kwDOCLPERc4BT-1s"
$statusFieldId = "PVTSSF_lADOCLPERc4BT-1szhBKDNA"
$doneOptionId = "c66aa76a"

# Verify if gh is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "The GitHub CLI ('gh') is not installed or not in the PATH. Aborting."
    exit 1
}

$itemsJson = Get-Content -Raw -Path ".claude/pipeline/items_live_1000.json" -Encoding UTF8 | ConvertFrom-Json
$items = $itemsJson.items

$count = 0
foreach ($item in $items) {
    # Skip if already in Done
    if ($item.status -eq "Done") { continue }
    
    $shouldClose = $false
    $title = $item.title
    $number = $item.content.number
    
    # Exclusions
    # Do NOT close ESP-077 #141 (our current restoration task)
    if ($number -eq 141) { continue } 
    
    # Check for ESP-XXX pattern up to 074 (including #138)
    if ($title -match "ESP-(\d+)") {
        $espNum = [int]$matches[1]
        if ($espNum -le 74) {
            $shouldClose = $true
        }
    }
    
    # ESP-060 #139 is a duplicate and should be closed according to drift correction
    if ($number -eq 139) { $shouldClose = $true }
    
    # Check for [Legado #XX] pattern
    if ($title -match "\[Legado #\d+\]") {
        $shouldClose = $true
    }
    
    # Specific items identified in audit
    if ($number -eq 36 -or $number -eq 80) {
        $shouldClose = $true
    }

    if ($shouldClose) {
        Write-Host "Moving item #$number '$title' ($($item.id)) to Done..."
        gh project item-edit --project-id $projectId --id $item.id --field-id $statusFieldId --single-select-option-id $doneOptionId
        $count++
        # Sleep to avoid rate limits if there are many (though my audit only found 3)
        Start-Sleep -Milliseconds 200
    }
}

Write-Host "`nFinished. Reconciled $count items to Done."
