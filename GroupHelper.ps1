Import-Module ActiveDirectory

class GroupHelper{
    [string]$specifiedOUPath
    GroupHelper([string]$OUPath){
        $this.specifiedOUPath=$OUPath
    }

    [bool] CheckGroupExists([string]$identity){
        $group=$this.GetGroupByIdentity($identity)
        if($null -ne $group){return $true}
        return $false
    }
    
    [string] GetGroupByIdentity([string]$identity){
        $group=Get-ADGroup -Filter * -SearchBase $this.specifiedOUPath -Properties * | Where-Object{$_.SamAccountName -eq $identity}
        if($null -eq $group){return $null}
    
        if($group.Count -gt 1){
            return ConvertTo-Json([PSCustomObject]@{
                group=$group[0]
                message="Multiple groups found with the given idendtity.`nPlease specify a search path."
            })
        }
        return ConvertTo-Json $group
    }
    
    [string] GetGroupsByUser([string]$userName){
        $user=Get-ADUser -Identity $userName -Properties MemberOf
        if($null -ne $user){
            $groups=$user.MemberOf|ForEach-Object{
                (Get-ADGroup -Identity $_ -Properties Name).Name
            }
            return ConvertTo-Json $groups
        }
        return $null
    }
    
    [string] AddNewGroup([string]$groupName,[string]$samAccountName,[string]$groupCategory,[string]$groupScope,[string]$processOUPath){
        if($processOUPath -eq ""){$this.specifiedOUPath=$processOUPath}
        $isGroupNameProper=$this.CheckGroupExists($groupName)
        if(-not $isGroupNameProper){
            $group=New-ADGroup -Name $groupName -SamAccountName $samAccountName -GroupCategory $groupCategory -GroupScope $groupScope -Path $this.specifiedOUPath
            return ConvertTo-Json $group
        }else{
            Write-Host "Group $groupName already exists."
            return $null
        }
    }
    
    [string] AddGroupToGroup([string]$parentGroup,[string]$childGroup){
        $parentGroupExists=$this.CheckGroupExists($parentGroup)
        $childGroupExists=$this.CheckGroupExists($childGroup)
        if($parentGroupExists){
            if($childGroupExists){
                Add-ADGroupMember -Identity $parentGroup -Members $childGroup
                return ConvertTo-Json $childGroup
            }
            return ConvertTo-Json "Child group does not exist!"
        }
        return ConvertTo-Json "Parent group does not exist!"
    }
    
    [string] RemoveGroup([string]$identity,[string]$OUPath=""){
        $group=$this.GetGroupByIdentity($identity,$OUPath)
        if($null -ne $group){
            Remove-ADGroup -Identity $identity -Confirm:$false
            return ConvertTo-Json $group
        }
        return $null
    }
    
    [string] RemoveGroupFromGroup([string]$parentGroup,[string]$childGroup){
        $parentGroupExists=$this.CheckGroupExists($parentGroup)
        $childGroupExists=$this.CheckGroupExists($childGroup)
        if($parentGroupExists){
            if($childGroupExists){
                Remove-ADGroupMember -Identity $parentGroup -Members $childGroup
                return ConvertTo-Json $childGroup
            }
            return ConvertTo-Json "Child group does not exist!"
        }
        return ConvertTo-Json "Parent group does not exist!"
    }
}