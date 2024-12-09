class GenericHelper{
    static [psobject] ConvertJSONToPSData([string]$jsonData){
        try{return ConvertFrom-Json $jsonData}
        catch{throw "Invalid JSON data: $($_.Exception.Message)"}
    }

    static [string] GeneratePassword([int]$length){
        if($length -le 0){throw "Password length must be greater than zero."}
        $characters="1234567890!@#$%#&*()qazwsxedcrfvtgbyhnujmkolpiQAZWSXEDCRFVTGBYHNUJMKOLPI"
        $random=1..$length|ForEach-Object{Get-Random -Maximum $characters.Length}
        $private:ofs=""
        return [string]$characters[$random]
    }

    static [string] ValidateEmailAddress([string]$emailAddress){
        if([string]::IsNullOrWhiteSpace($emailAddress)){return ""}
        return $emailAddress -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    }
}