Import-Module ActiveDirectory

class GroupHelper{
    [string]$specifiedOUPath

    GroupHelper([string]$OUPath){
        $this.specifiedOUPath=if($OUPath -eq ""){"OU=OUTest,DC=taslogwinserver,DC=local"}
        else{$OUPath}
    }

    # [bool] CheckGroupExists([string]$identity){
    #     $group=$this.GetGroupByIdentity($identity)
    #     if($group -eq ""){return $false}
    #     return $true
    # }

    [bool] CheckGroupExists([string]$identity){
        $group=$this.GetGroupByIdentity($identity)
        return ($group -ne "")
    }
    
    [string] GetGroupByIdentity([string]$identity){
        $group=Get-ADGroup -Filter * -SearchBase $this.specifiedOUPath -Properties * | Where-Object{$_.SamAccountName -eq $identity}
        if($null -eq $group){return ""}
    
        if($group.Count -gt 1){
            return ConvertTo-Json([PSCustomObject]@{
                group=$group[0]
                message="Multiple groups found with the given idendtity.`nPlease specify a search path."
            })
        }
        return ConvertTo-Json $group
    }
    
    # [string] GetGroupsByUser([string]$userName){
    #     $user=Get-ADUser -Identity $userName -Properties MemberOf
    #     if($null -ne $user){
    #         $groups=$user.MemberOf|ForEach-Object{
    #             (Get-ADGroup -Identity $_ -Properties Name).Name
    #         }
    #         return ConvertTo-Json $groups
    #     }
    #     return $null
    # }

    [string] GetGroupsByUser([string]$userName){
        $user=Get-ADUser -Identity $userName -Properties MemberOf
        $groups=$user.MemberOf | ForEach-Object {(Get-ADGroup -Identity $_).Name}
        return $groups | ConvertTo-Json
    }

    [string] GetUsersByGroup([string]$groupName){
        if($this.CheckGroupExists($groupName)){
            $memberList=Get-ADGroup -Filter "SamAccountName -eq '$groupName'" -Properties Member | Select-Object -ExpandProperty Member
            return $memberList | ConvertTo-Json
        }
        return ""
    }
    
    # [string] AddNewGroup([string]$groupName,[string]$samAccountName,[string]$groupCategory,[string]$groupScope,[string]$processOUPath){
    #     $OUPath=if($processOUPath -ne ""){$processOUPath}
    #     else{$this.specifiedOUPath}
    #     $isGroupNameProper=$this.CheckGroupExists($groupName)
    #     if(-not $isGroupNameProper){
    #         $group=New-ADGroup -Name $groupName -SamAccountName $samAccountName -GroupCategory $groupCategory -GroupScope $groupScope -Path $OUPath
    #         return ConvertTo-Json $group
    #     }
    #     else{return $null}
    # }

    [string] AddNewGroup([string]$groupName,[string]$samAccountName,[string]$groupCategory,[string]$groupScope,[string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedOUPath}
        if (-not $this.CheckGroupExists($groupName)){
            New-ADGroup -Name $groupName -SamAccountName $samAccountName -GroupCategory $groupCategory -GroupScope $groupScope -Path $OUPath
            return $groupName
        }
        return ""
    }
    
    [string] AddGroupToGroup([string]$parentGroup,[string]$childGroup){
        $parentGroupExists=$this.CheckGroupExists($parentGroup)
        $childGroupExists=$this.CheckGroupExists($childGroup)
        if($parentGroupExists){
            if($childGroupExists){
                Add-ADGroupMember -Identity $parentGroup -Members $childGroup
                return $childGroup
            }
            return "Child group does not exist!"
        }
        return "Parent group does not exist!"
    }
    
    # [string] RemoveGroup([string]$identity){
    #     $group=$this.CheckGroupExists($identity)
    #     if($group){
    #         Remove-ADGroup -Identity $identity -Confirm:$false
    #         return ConvertTo-Json $identity
    #     }
    #     return ""
    # }

    [string] RemoveGroup([string]$identity) {
        if ($this.CheckGroupExists($identity)) {
            Remove-ADGroup -Identity $identity -Confirm:$false
            return $identity
        }
        return ""
    }
    
    [string] RemoveGroupFromGroup([string]$parentGroup,[string]$childGroup){
        $parentGroupExists=$this.CheckGroupExists($parentGroup)
        $childGroupExists=$this.CheckGroupExists($childGroup)
        if($parentGroupExists){
            if($childGroupExists){
                Remove-ADGroupMember -Identity $parentGroup -Members $childGroup -Confirm:$false
                return $childGroup
            }
            return ""
        }
        return ""
    }
}