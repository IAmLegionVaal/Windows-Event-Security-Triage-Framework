# Windows Event Security Triage Framework

A read-only PowerShell framework for reviewing Windows security and operational event data.

## Features

- Configurable lookback period
- Event grouping by source and identifier
- Timeline and frequency summaries
- CSV, JSON, and HTML reports
- Technician-friendly evidence collection

## Run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Windows_Event_Security_Triage_Framework.ps1
```

Custom lookback period:

```powershell
.\Windows_Event_Security_Triage_Framework.ps1 -Hours 72
```

## Safety

Read-only reporting. No event logs or system settings are changed.
