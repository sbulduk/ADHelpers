class RemoteHelper{
    [string]$remoteServer
    [System.Management.Automation.PSCredential]$credential

    RemoteHelper([string]$remoteServer,[System.Management.Automation.PSCredential]$credential){
        $this.remoteServer=$remoteServer
        $this.credential=$credential
    }

    [bool] TestConnection(){
        try{
            Test-Connection -ComputerName $this.remoteServer -Count 1 -Quiet -Credential $this.credential
            return $true
        }catch{
            Write-Error "Connection test failed: $($_.Exception.Message)"
            return $false
        }
    }

    [psobject] InvokeRemoteScript([scriptblock]$scriptBlock,[hashtable]$params=@{}){
        try{
            $command=Invoke-Command -ComputerName $this.remoteServer -Credential $this.credential -ScriptBlock $scriptBlock -ArgumentList ($params.Values)
            return $command
        }catch{
            Write-Error "Error executing remote script: $($_.Exception.Message)"
            return $null
        }
    }

    [string] RunScriptFile([string]$filePath,[hashtable]$params=@{}){
        Write-Output "A"
        if($null -eq (Test-Path $filePath)){throw "The script file '$filePath' does not exist!"}
        Write-Output "B"

        try{
            Write-Output "C"
            $scriptContent=Get-Content -Path $filePath -Raw
            Write-Output "D"
            $scriptBlock=[scriptblock]::Create($scriptContent)
            Write-Output "E"
            return $this.InvokeRemoteScript($scriptBlock,$params)
        }catch{
            Write-Output "F"
            return $null}
    }

    [psobject] RunMethod([string]$className,[string]$methodName,[hashtable]$params=@{}){
        $scriptBlock={
            param ($className,$methodName,$params)
            Import-Module ActiveDirectory -ErrorAction SilentlyContinue
            $instance=New-Object -TypeName $className
            $method=$instance.PSObject.Methods[$methodName]
            if($null -eq $method){
                throw "Method '$methodName' does not exist in class '$className'."
            }
            return $method.Invoke($params.Values)
        }

        return $this.InvokeRemoteScript($scriptBlock,@{
            className=$className
            methodName=$methodName
            params=$params
        })
    }
}