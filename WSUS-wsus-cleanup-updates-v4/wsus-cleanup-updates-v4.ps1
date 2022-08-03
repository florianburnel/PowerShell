<#

    WSUS-CLEANUP-UPDATES
    
    Runs WSUS cleanup task using stored procedures in WSUS database
    thus avoiding timeout errors that may occur when running WSUS Cleanup Wizard.

    The script is intended to run as a scheduled task on WSUS server
    but can also be used remotely. $SqlServer and $SqlDB variables 
    must be defined before running the script on a server without WSUS.

    Version 4

    Version history:

    4    Added database connection state check before deleting an 
         unused update: the script will now attempt to reestablish
         connection if broken.


#>


##########################
# Configurable parameters

$SqlServer = ""    # SQL server host name; leave empty to use information from local registry
$SqlDB = "SUSDB"   # WSUS database name     
$SkipFileCleanup = $SqlServer -ne ""

$log_source = "WSUS cleanup Task"  # Event log source name
$log_debugMode = $true  # set to false to suppress console output 


##########################


$ErrorActionPreference = "Stop"

# basic logging facility

function log_init{
    if ( -not [System.Diagnostics.EventLog]::SourceExists($log_source) ){
        [System.Diagnostics.EventLog]::CreateEventSource($log_source, "Application")
    }
}

function log( [string] $msg, [int32] $eventID, [System.Diagnostics.EventLogEntryType] $level ){
    Write-EventLog -LogName Application -Source $log_source -EntryType $level -EventId $eventID -Message $msg 
    if ( $log_debugMode ){
        switch ($level){
            Warning {Write-Host $msg -ForegroundColor Yellow }
            Error { Write-Host $msg -ForegroundColor Red }
            default { Write-Host $msg -ForegroundColor Gray }
        }
    }
}

function dbg( [string] $msg ){
    if ( $log_debugMode ){ 
        log "DBG: $msg"  300 "Information"
    }
}

log_init


#########################


function DeclineExpiredUpdates( $dbconn ){

    log "Declining expired updates" 1 "Information"

    $Command = New-Object System.Data.SQLClient.SQLCommand 
    $Command.Connection = $dbconn 
    $Command.CommandTimeout = 3600
    $Command.CommandText = "EXEC spDeclineExpiredUpdates"
    try{
        $Command.ExecuteNonQuery() | Out-Null
    }
    catch{
        $script:errorCount++
        log "Exception declining expired updates:`n$_" 99 "Error"
    }
}

#########################

function DeclineSupersededUpdates( $dbconn ){

    log "Declining superseded updates" 1 "Information"
    
    $Command = New-Object System.Data.SQLClient.SQLCommand 
    $Command.Connection = $dbconn 
    $Command.CommandTimeout = 1800
    $Command.CommandText = "EXEC spDeclineSupersededUpdates"
    try{
        $Command.ExecuteNonQuery() | Out-Null
    }
    catch{
        $script:errorCount++
        log "Exception declining superseded updates:`n$_" 99 "Error"
    }
}


#######################

function DeleteObsoleteUpdates( $dbconn ){

        Log "Reading obsolete update list." 1 "Information"
        $Command = New-Object System.Data.SQLClient.SQLCommand 
        $Command.Connection = $dbconn 
        $Command.CommandTimeout = 600
        $Command.CommandText = "EXEC spGetObsoleteUpdatesToCleanup" 
        $reader = $Command.ExecuteReader()
        $table = New-Object System.Data.DataTable 
        $table.Load($reader)

        $updatesTotal = $table.Rows.Count
        log "Found $updatesTotal updates that can be deleted." 1 "Information"

        $updatesProcessed=0
        $Command.CommandTimeout = 300
        foreach( $row in $table.Rows ){
            try{
                if ( $dbconn.State -ne [System.Data.ConnectionState]::Open ){
                    log "Re-opening database connection" 2 "Warning"
                    $dbconn.Open()
                }
                $updatesProcessed++
                log "Deleting update $($row.localUpdateID) ($updatesProcessed of $updatesTotal)" 1 "Information"
                $Command.CommandText = "exec spDeleteUpdate @LocalUpdateID=$($row.localUpdateID)"
                $Command.ExecuteNonQuery() | Out-Null
            }
            catch{
                $errorCount++
                log "Error deleting update $($row.localUpdateID):`n$_" 8 "Warning"
            }
        }

}

###################


function DbConnectionString{

    $WsusSetupKey = "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup"

    if ( $script:SqlServer -eq "" ){
        $server = Get-ItemProperty -path $WsusSetupKey -Name "SqlServerName" -ErrorAction SilentlyContinue
        $db = Get-ItemProperty -path $WsusSetupKey -Name "SqlDatabaseName" -ErrorAction SilentlyContinue
        if ( ! $server  ){
            throw "Cannot determine SQL server name" 
        }
        $script:SqlServer = $server.SqlServerName
        $script:SqlDB = $db.SqlDatabaseName
    }

    if ( $script:SqlServer -match "microsoft##" ){
        return "data source=\\.\pipe\$script:SqlServer\tsql\query;Integrated Security=True;database='$script:SqlDB';Network Library=dbnmpntw"
    }
    else{
        return "server='$script:SqlServer';database='$script:SqlDB';trusted_connection=true;" 
    }

}


##############

function DeleteUnusedContent{

    log "Deleting unneeded content files" 1 "Information"
    
    try{
        Import-Module UpdateServices
        $status = Invoke-WsusServerCleanup -CleanupUnneededContentFiles 
        log "Done deleting unneeded content files: $status" 1 "Information"
    }
    catch{
        $script:errorCount++
        log "Exception deleting unneeded content files:`n$_" 99 "Error"
    }

}


###################

function DeleteInactiveComputers( $DbConn ){

    log "Removing obsolete computers" 1 "Information"
    
    $Command = New-Object System.Data.SQLClient.SQLCommand 
    $Command.Connection = $dbconn 
    $Command.CommandTimeout = 1800
    $Command.CommandText = "EXEC spCleanupObsoleteComputers"
    try{
        $Command.ExecuteNonQuery() | Out-Null
    }
    catch{
        $script:errorCount++
        log "Exception removing obsolete computers:`n$_" 99 "Error"
    }

}

function RestartWsusService{
    log "Stopping IIS.." 1 "Information"
    try{
        Stop-Service W3SVC -Force
        try{
            log "Restarting WSUS service.." 1 "Information"
            Restart-Service WsusService -Force 
        }
        finally{
            log "Starting IIS..." 1 "Information"
            Start-Service W3SVC 
        }
    }
    catch{
        $script:errorCount++
        log "Error restarting WSUS services:`n$_" 99 "Error"        
    }
    Start-Sleep -Seconds 30
}

<#------------------------------------------------
                     MAIN                         
-------------------------------------------------#>


$timeExecStart = Get-Date
$errorCount = 0

try{
    
    $Conn = New-Object System.Data.SQLClient.SQLConnection 
    $Conn.ConnectionString = DbConnectionString
    log "Connecting to database $SqlDB on $SqlServer" 1 "Information"
    $Conn.Open() 
    try{
        DeclineExpiredUpdates $Conn
        DeclineSupersededUpdates $Conn
        DeleteObsoleteUpdates $Conn
        DeleteInactiveComputers $Conn   
        RestartWsusService   
        if ( ! $SkipFileCleanup ) {  
            DeleteUnusedContent 
        }
    }
    finally{
        $Conn.Close() 
    }

}
catch{
    $errorCount++
    log "Unhandled exception:`n$_" 100 "Error"
}

$time_exec = ( Get-Date ) - $timeExecStart
log "Completed script execution with $errorCount error(s)`nExecution time $([math]::Round($time_exec.TotalHours)) hours and $([math]::Round($time_exec.totalMinutes)) minutes." 1 "Information"
