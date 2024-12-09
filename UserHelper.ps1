Import-Module ActiveDirectory
# Set-Location -Path .
# Import-Module .\GenericHelper.ps1
. .\GroupHelper.ps1

class UserHelper{
    [string]$specifiedOUPath

    UserHelper([string]$OUPath){
        $this.specifiedOUPath=if($OUPath -eq ""){"OU=OUTest,DC=taslogwinserver,DC=local"}
        else{$OUPath}
    }

    # [bool] CheckUserExists([string]$identity){
    #     # $user=Get-ADUser -Filter "SamAccountName -eq '$identity'" -Properties * -ErrorAction SilentlyContinue
    #     $user=$this.GetUserByIdentity($identity)
    #     if($user -eq ""){return $false}
    #     return $true
    # }

    [bool] CheckUserExists([string]$identity){
        $user=$this.GetUserByIdentity($identity)
        return ($user -ne "")
    }

    [string] GetUserByIdentity([string]$identity){
        $user=Get-ADUser -Filter "SamAccountName -eq '$identity'" -SearchBase $this.specifiedOUPath -Properties * -ErrorAction SilentlyContinue
        if($user){return ConvertTo-Json $user}
        return ""
    }

    # [string] GetUsersByGroup([string]$groupName){
    #     $users=Get-ADGroupMember -Identity $groupName
    #     if($users){return ConvertTo-Json $users.Name}
    #     return ""
    # }

    [string] GetUsersByGroup([string]$groupName){
        $users=Get-ADGroupMember -Identity $groupName | Where-Object {$_.objectClass -eq "user"}
        return $users.Name | ConvertTo-Json
    }

    # [string] GetUsersByOU([string]$processOUPath){
    #     $OUPath=if($processOUPath -ne ""){$processOUPath}
    #     else{$this.specifiedOUPath}
    #     $users=Get-ADUser -Filter * -SearchBase $OUPath -Properties *
    #     if($users){return ConvertTo-json $users.Name}
    #     return ""
    # }

    [string] GetUsersByOU([string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        $users=Get-ADUser -Filter * -SearchBase $OUPath -Properties *
        return $users.Name | ConvertTo-Json
    }

    # [string] SearchUser([string]$searchParameter,[string]$parameterValue,[string]$processOUPath){
    #     $OUPath=if($processOUPath -ne ""){$processOUPath}
    #     else{$this.specifiedOUPath}
    #     $filter="$($searchParameter) -like '*$($parameterValue)*'"
    #     $users=Get-ADUser -Filter $filter -Properties * -SearchBase $OUPath

    #     if($users.Count -gt 0){
    #         if($users.Count -gt 1){return $users | Select-Object -ExpandProperty SamAccountName}
    #         return ConvertTo-Json $users.Name
    #     }
    #     return ""
    # }

    [string] SearchUser([string]$searchParameter,[string]$parameterValue,[string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        $filter="$($searchParameter) -like '*$($parameterValue)*'"
        $users=Get-ADUser -Filter $filter -SearchBase $OUPath -Properties *
        return $users | Select-Object -ExpandProperty SamAccountName | ConvertTo-Json
    }

    # [string] AddNewUser([string]$firstName,[string]$lastName,[string]$processOUPath){
    #     $fullName="$firstName $lastName"
    #     # $password=ConvertTo-SecureString -String $([GenericHelper]GeneratePassword(16)) -AsPlainText -Force
    #     $password=ConvertTo-SecureString -String ("DefaultTasLogPass1864!") -AsPlainText -Force
    #     $userName="$firstName.$lastName"
    #     $OUPath=if($processOUPath -ne ""){$processOUPath}
    #     else{$this.specifiedOUPath}
    #     if(-not $this.CheckUserExists($userName)){
    #         $user=New-ADUser -Name $fullName -GivenName $firstName -Surname $lastName -SamAccountName $userName -UserPrincipalName $userName -AccountPassword $password -Enabled $True -Path $OUPath
    #         return ConvertTo-Json $userName
    #     }
    #     return ""
    # }

    [string] AddNewUser([string]$firstName,[string]$lastName,[string]$processOUPath) {
        $fullName="$firstName $lastName"
        $password=ConvertTo-SecureString -String("DefaultTasLogPass1864!") -AsPlainText -Force
        $userName="$firstName.$lastName"
        $OUPath=if ($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        if (-not $this.CheckUserExists($userName)) {
            New-ADUser -Name $fullName -GivenName $firstName -Surname $lastName -SamAccountName $userName -UserPrincipalName $userName -AccountPassword $password -Enabled $True -Path $OUPath
            return $userName
        }
        return ""
    }

    [string] AddUserToGroup([string]$userName,[string]$groupName){
        Add-ADGroupMember -Identity $groupName -Members $userName
        return $userName
    }

    [string] RemoveUser($identity){
        if ($this.CheckUserExists($identity)) {
            Remove-ADUser -Identity $identity -Confirm:$false
            return $identity
        }
        return ""
    }

    [bool] ResetUserPassword([string]$identity,[string]$newPassword) {
        $user=$this.CheckUserExists($identity)
        if ($user){
            $password=ConvertTo-SecureString -String($newPassword) -AsPlainText -Force
            Set-ADAccountPassword -Identity $identity -Reset -NewPassword $password
            return $true
        }
        return $false
    }

    [string] EnableUser([string]$identity) {
        if ($this.CheckUserExists($identity)) {
            Enable-ADAccount -Identity $identity
            return $identity
        }
        return ""
    }

    [string] DisableUser([string]$identity) {
        if ($this.CheckUserExists($identity)) {
            Disable-ADAccount -Identity $identity
            return $identity
        }
        return ""
    }
}