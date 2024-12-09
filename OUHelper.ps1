Import-Module ActiveDirectory

class OUHelper{
    [string]$specifiedDomain

    OUHelper([string]$domain){
        $this.specifiedDomain=if($domain -ne ""){$domain}else{"DC=taslogwinserver,DC=local"}
    }

    [bool] CheckOUExists([string]$OUPath){
        $OU=Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $OUPath} -ErrorAction SilentlyContinue
        return ($null -ne $OU)
    }

    [string] GetOUByName([string]$OUName){
        $OU=Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -Properties *
        return $OU | ConvertTo-Json -Depth 3
    }

    [string] GetOUHierarch([string]$processOUPath){
        $OUPath=if($processOUPath -eq ""){$this.specifiedDomain}else{$this.$processOUPath}
        if(-not $this.CheckOUExists($OUPath)){return ""}
        $hierarchy=Get-ADOrganizationalUnit -Filter * -SearchBase $OUPath
        return $hierarchy | ConvertTo-Json -Depth 3
    }

    [string] ListOUs([string]$processOUPath){
        $OUPath=if($processOUPath -ne ""){$processOUPath}else{$this.specifiedDomain}
        $OUs=Get-ADOrganizationalUnit -Filter * -SearchBase $OUPath
        return $OUs.DistinguishedName | ConvertTo-Json
    }

    [string] AddNewOU([string]$OUName,[string]$parentOUPath){
        $OUPath=if($parentOUPath -ne ""){$parentOUPath}else{$this.specifiedDomain}
        $fullPath="OU=$OUName,$OUPath"
        if (-not $this.CheckOUExists($fullPath)){
            New-ADOrganizationalUnit -Name $OUName -Path $OUPath
            return $fullPath
        }
        return ""
    }

    [string] RemoveOU([string]$OUPath){
        if ($this.CheckOUExists($OUPath)){
            Remove-ADOrganizationalUnit -Identity $OUPath -Recursive -Confirm:$false
            return $OUPath
        }
        return ""
    }

    [string] MoveOU([string]$sourceOUPath,[string]$destinationOUPath){
        if ($this.CheckOUExists($sourceOUPath)){
            Move-ADObject -Identity $sourceOUPath -TargetPath $destinationOUPath
            return $destinationOUPath
        }
        return ""
    }

    [string] GetOUChildObjects([string]$OUPath){
        if ($this.CheckOUExists($OUPath)){
            $children=Get-ADObject -Filter * -SearchBase $OUPath
            return $children | ConvertTo-Json -Depth 3
        }
        return ""
    }
}