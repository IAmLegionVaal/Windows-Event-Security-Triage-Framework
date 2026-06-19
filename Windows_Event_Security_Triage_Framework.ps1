#requires -Version 5.1
[CmdletBinding()]
param([int]$Hours=48,[int]$MaxEvents=1000,[string]$OutputPath)

$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Windows_Event_Triage_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
$start=(Get-Date).AddHours(-1*$Hours)

$logs=@(
    'Security',
    'System',
    'Microsoft-Windows-Windows Defender/Operational'
)

$events=[System.Collections.Generic.List[object]]::new()
foreach($log in $logs){
    try{
        $items=Get-WinEvent -FilterHashtable @{LogName=$log;StartTime=$start} -ErrorAction Stop|Select-Object -First $MaxEvents
        foreach($item in $items){
            $events.Add([PSCustomObject]@{
                TimeCreated=$item.TimeCreated
                LogName=$item.LogName
                Id=$item.Id
                ProviderName=$item.ProviderName
                Level=$item.LevelDisplayName
                RecordId=$item.RecordId
                Message=$item.Message
            })
        }
    }catch{
        $events.Add([PSCustomObject]@{
            TimeCreated=Get-Date
            LogName=$log
            Id=$null
            ProviderName='Collector'
            Level='Information'
            RecordId=$null
            Message="Log unavailable: $($_.Exception.Message)"
        })
    }
}

$frequency=$events|Where-Object{$_.Id -ne $null}|Group-Object LogName,ProviderName,Id|Sort-Object Count -Descending|ForEach-Object{
    [PSCustomObject]@{
        Count=$_.Count
        LogName=$_.Group[0].LogName
        ProviderName=$_.Group[0].ProviderName
        EventId=$_.Group[0].Id
        Latest=($_.Group|Sort-Object TimeCreated -Descending|Select-Object -First 1).TimeCreated
    }
}

$timeline=$events|Sort-Object TimeCreated -Descending|Select-Object -First 250
$summary=[PSCustomObject]@{
    Computer=$env:COMPUTERNAME
    LookbackHours=$Hours
    TotalEvents=@($events).Count
    DistinctEventGroups=@($frequency).Count
    Generated=Get-Date
}

$events|Export-Csv (Join-Path $OutputPath "events_$stamp.csv") -NoTypeInformation -Encoding UTF8
$frequency|Export-Csv (Join-Path $OutputPath "event_frequency_$stamp.csv") -NoTypeInformation -Encoding UTF8
$timeline|Export-Csv (Join-Path $OutputPath "event_timeline_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;Frequency=$frequency;Timeline=$timeline}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $OutputPath "event_triage_$stamp.json") -Encoding UTF8

$html="<h1>Windows Event Security Triage - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Most Frequent Events</h2>$($frequency|Select-Object -First 100|ConvertTo-Html -Fragment)<h2>Recent Timeline</h2>$($timeline|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Windows Event Security Triage'|Set-Content (Join-Path $OutputPath "event_triage_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
