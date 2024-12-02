Import-Module ActiveDirectory
# Set-Location -Path .
# Import-Module .\GenericHelper.ps1

class UserHelper{
    [string]$specifiedOUPath

    UserHelper([string]$OUPath){
        if($OUPath -eq ""){$this.specifiedOUPath=""}
        else{$this.specifiedOUPath=$OUPath}
    }

    [string] CheckUserExists([string]$identity){
        $user=$this.GetUserByIdentity($identity)
        if($user){return $true}
        return $false
    }

    [string] GetUserByIdentity([string]$identity){
        $user=Get-ADUser -Filter "SamAccountName -eq '$identity'" -SearchBase $this.specifiedOUPath -Properties * -ErrorAction SilentlyContinue
        if(!$user){return $false}
        return ConvertTo-Json $user
    }

    [string] GetUsersByGroup([string]$groupName){
        $users=Get-ADGroupMember -Identity $groupName -SearchBase $this.specifiedOUPath
        if($users){return ConvertTo-Json $users.Name}
        return $null
    }

    [string] GetUsersByOU([string]$processOUPath){
        if($processOUPath -ne ""){$this.defaultOUPath=$processOUPath}
        $users=Get-ADUser -Filter * -SearchBase $this.specifiedOUPath -Properties *
        if($users){return ConvertTo-json $users}
        return $null
    }

    [string] SearchUser([string]$searchParameter,[string]$parameterValue,[string]$processOUPath){
        if($processOUPath -ne ""){$this.defaultOUPath=$processOUPath}
        $filter="$($searchParameter) -like '*$($parameterValue)*'"
        $users=Get-ADUser -Filter $filter -Properties * -SearchBase $processOUPath

        if($users.Count -gt 0){
            if($users.Count -gt 1){return $users | Select-Object -ExpandProperty SamAccountName}
            return ConvertTo-Json $users.SamAccountName
        }
        return "User not found."
    }

    [string] AddNewUser([string]$firstName,[string]$lastName,[string]$processOUPath){
        $fullName="$firstName $lastName"
        # $password=ConvertTo-SecureString -String $([GenericHelper]GeneratePassword(16)) -AsPlainText -Force
        $password="DefaultTasLogPass1864!"
        $userName="$firstName.$lastName"
        if($processOUPath -ne ""){$this.specifiedOUPath=$processOUPath}
        if(-not $this.CheckUserExists($userName)){
            $user=New-ADUser -Name $fullName -GivenName $firstName -Surname $lastName -SamAccountName $userName -UserPrincipalName $userName -AccountPassword $password -Enabled $True -Path $this.specifiedOUPath
            return ConvertTo-Json $user
        }
        return "User already exists."
    }

    [string] AddUserToGroup([string]$userName,[string]$groupName){
        Add-ADGroupMember -Identity $groupName -Members $userName
        return ConvertTo-Json $userName
    }

    [string] RemoveUser($identity){
        # TODO: Delete selected user.
        return ""
    }
}