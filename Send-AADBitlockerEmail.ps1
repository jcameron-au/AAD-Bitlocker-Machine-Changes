function Send-AADBitlockerEmail {
    [CmdletBinding()]
    Param(
        $Content,

        $smtpCredential
    )
    
    Begin {

        $css = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

        $pre = '<h2>Machines with Bitlocker Changes:</h2><br>'

        if (!([String]::IsNullOrEmpty($Content.DisplayName))) {
            $post = "<br><i>Report generated on $((Get-Date).ToString()) by Start-AADBitlockerReport.ps1 on $($Env:Computername)</i>"
            $mailBody = $Content | ConvertTo-Html -PreContent $pre -PostContent $post -Head $css
        } else {

            $post = "<h4>No machines changed in the last week.</h4><br><br><i>Report generated on $((Get-Date).ToString()) by Start-AADBitlockerReport.ps1 on $($Env:Computername)</i>"
            $mailBody = $Content | ConvertTo-Html -PreContent $pre -PostContent $post -Head $css
        }

        

        $mailParams = @{

            To = 'user@domain.com'
            From = 'user@domain.com'
            Subject = "Bitlocker Report [$((Get-Date).ToString())]"
            Body = "$($mailBody)"
            SmtpServer = 'xxx.xxx.xxx.xxx'
            Port = 'xxx'
            Credential = $smtpCredential

        }
        
    }

    Process {

        Send-MailMessage @mailParams -UseSsl -BodyAsHtml
        
    }

    End {
        
    }
}