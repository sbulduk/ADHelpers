class RemoteHelper{
    [string]$remoteServer
    [System.Management.Automation.PSCredential]$credential

    RemoteHelper([string]$remoteServer,[System.Management.Automation.PSCredential]$credential){
        $this.remoteServer=$remoteServer
        $this.credential=$credential
    }

    RemoteHelper([string]$remoteServer,[string]$userName,[string]$password){
        $this.remoteServer=$remoteServer
        $this.credential=New-Object System.Management.Automation.PSCredential($userName,(ConvertTo-SecureString -String($password) -AsPlainText -Force))
    }

    [bool] TestConnection(){
        try{
            Test-NetConnection -ComputerName $this.remoteServer -Port 445
            # Test-Connection -ComputerName $this.remoteServer -Count 1 -Quiet -Credential $this.credential
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
        if($null -eq (Test-Path $filePath)){throw "The script file '$filePath' does not exist!"}

        try{
            $scriptContent=Get-Content -Path $filePath -Raw
            $scriptBlock=[scriptblock]::Create($scriptContent)
            return $this.InvokeRemoteScript($scriptBlock,$params)
        }
        catch{return $null}
    }

    [psobject] RunMethod([string]$className,[string]$methodName,[hashtable]$params=@{}){
        $scriptBlock={
            param (
                [string]$className,
                [string]$methodName,
                [hashtable]$params
            )
            Import-Module ActiveDirectory -ErrorAction SilentlyContinue
            $instance=New-Object -TypeName $className
            $method=$instance.PSObject.Methods[$methodName]
            if($null -eq $method){
                throw "Method '$methodName' does not exist in class '$className'."
            }
            $result=$method.Invoke($params.Values)
            return $result
        }

        return $this.InvokeRemoteScript($scriptBlock,@{
            className=$className
            methodName=$methodName
            params=$params
        })
    }
}