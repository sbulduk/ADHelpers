Import-Module ActiveDirectory

class ComputerHelper{
    [string]$specifiedOUPath

    ComputerHelper([string]$OUPath){
        $this.specifiedOUPath=if($OUPath -ne ""){$OUPath}else{"OU=Computers,DC=taslogwinserver,DC=local"}
    }

    [bool] CheckComputerExists([string]$computerName){
        if([string]::IsNullOrWhiteSpace($computerName)){return $false}
        $computer=Get-ADComputer -Filter "Name -eq '$computerName'" -Properties * -ErrorAction SilentlyContinue
        return ($false -ne $computer)
    }

    [string] GetComputerByName([string]$computerName){
        $computer=$this.CheckComputerExists($computerName)
        # $computer=Get-ADComputer -Filter "Name -eq '$computerName'" -Properties *
        return $computer | ConvertTo-Json -Depth 3
    }

    [string] ListComputersInOU([string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        $computers=Get-ADComputer -Filter * -SearchBase $OUPath
        return $computers.Name | ConvertTo-Json
    }

    [string] AddNewComputer([string]$computerName,[string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        if (-not $this.CheckComputerExists($computerName)){
            New-ADComputer -Name $computerName -Path $OUPath -Enabled $true
            return $computerName
        }
        return ""
    }

    [string] RemoveComputer([string]$computerName){
        if($this.CheckComputerExists($computerName)){
            Remove-ADComputer -Identity $computerName -Confirm:$false
            return $computerName
        }
        return ""
    }

    [string] MoveComputer([string]$computerName,[string]$destinationOUPath){
        if ($this.CheckComputerExists($computerName)){
            Move-ADObject -Identity (Get-ADComputer -Filter "Name -eq '$computerName'").DistinguishedName -TargetPath $destinationOUPath
            return $computerName
        }
        return ""
    }

    [string] ResetComputerAccount([string]$computerName){
        if ($this.CheckComputerExists($computerName)){
            Reset-ComputerMachinePassword -ComputerName $computerName
            return $computerName
        }
        return ""
    }
}